import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../core/utils/call_enums.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../services/calling_service.dart';
import '../../services/local_storage_service.dart';

part 'call_event.dart';
part 'call_state.dart';

/// Owns the entire call lifecycle described in the assignment:
/// Calling -> Ringing -> Connected -> In Call -> Ended
/// plus Rejected / Missed / Busy / Failed / Disconnected.
///
/// It sits on top of [CallingService] (LiveKit) and writes a record to
/// [LocalStorageService] once a call reaches a terminal state.
class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc(this._callingService, this._storage) : super(CallState.idle) {
    on<StartListeningForCalls>(_onStartListening);
    on<StopListeningForCalls>(_onStopListening);
    on<_SignalArrived>(_onSignalArrived);
    on<PlaceCall>(_onPlaceCall);
    on<CancelOutgoingCall>(_onCancelOutgoing);
    on<AcceptIncomingCall>(_onAcceptIncoming);
    on<DeclineIncomingCall>(_onDeclineIncoming);
    on<ToggleMicrophone>(_onToggleMic);
    on<ToggleCamera>(_onToggleCamera);
    on<ToggleSpeaker>(_onToggleSpeaker);
    on<SwitchCamera>(_onSwitchCamera);
    on<EndCall>(_onEndCall);
    on<_CallRoomEventArrived>(_onCallRoomEvent);
    on<_DurationTick>(_onDurationTick);
    on<ClearCallError>((e, emit) => emit(state.copyWith(clearError: true)));
    on<ResetCall>((e, emit) => emit(CallState.idle));
  }

  final CallingService _callingService;
  final LocalStorageService _storage;

  StreamSubscription? _signalSub;
  StreamSubscription? _callRoomEventsSub;
  Timer? _durationTimer;
  Timer? _ringTimeoutTimer;
  UserModel? _me;

  // ---------------- Signaling lifecycle ----------------

  Future<void> _onStartListening(StartListeningForCalls event, Emitter<CallState> emit) async {
    _me = event.me;
    await _callingService.startSignaling(event.me);
    await _signalSub?.cancel();
    _signalSub = _callingService.onSignal.listen((msg) => add(_SignalArrived(msg)));
  }

  Future<void> _onStopListening(StopListeningForCalls event, Emitter<CallState> emit) async {
    await _signalSub?.cancel();
    await _callingService.stopSignaling();
  }

  Future<void> _onSignalArrived(_SignalArrived event, Emitter<CallState> emit) async {
    final msg = event.message;

    if (msg.type == 'invite') {
      // Ignore new invites if we're already mid-call; politely say busy.
      if (state.phase.isActive) {
        if (_me != null) {
          await _callingService.sendBusy(me: _me!, toUserId: msg.fromId, callId: msg.callId);
        }
        return;
      }
      emit(CallState(
        phase: CallLifecycle.ringing,
        callId: msg.callId,
        roomName: msg.roomName,
        peerId: msg.fromId,
        peerName: msg.fromName,
        peerAvatarColorHex: msg.fromAvatarColorHex,
        type: msg.callType,
        direction: CallDirection.incoming,
      ));
      return;
    }

    if (msg.callId != state.callId) return; // signal for a stale/foreign call

    switch (msg.type) {
      case 'cancel':
        if (state.phase == CallLifecycle.ringing) {
          await _finishCall(emit, CallLifecycle.missed, CallStatus.missed);
        }
        break;
      case 'reject':
        if (state.phase == CallLifecycle.calling || state.phase == CallLifecycle.connecting) {
          await _finishCall(emit, CallLifecycle.rejected, CallStatus.rejected);
        }
        break;
      case 'busy':
        if (state.phase == CallLifecycle.calling) {
          await _finishCall(emit, CallLifecycle.busy, CallStatus.failed);
        }
        break;
    }
  }

  // ---------------- Outgoing ----------------

  Future<void> _onPlaceCall(PlaceCall event, Emitter<CallState> emit) async {
    final callId = _callingService.newCallId();
    final roomName = _callingService.roomNameForCall(callId);

    emit(CallState(
      phase: CallLifecycle.calling,
      callId: callId,
      roomName: roomName,
      peerId: event.peer.id,
      peerName: event.peer.name,
      peerAvatarColorHex: event.peer.avatarColorHex,
      type: event.type,
      direction: CallDirection.outgoing,
      cameraEnabled: event.type == CallType.video,
    ));

    try {
      final room = await _callingService.joinCallRoom(roomName: roomName, me: event.me, type: event.type);
      _listenToCallRoom();
      emit(state.copyWith(room: room));
      await _callingService.sendInvite(me: event.me, toUserId: event.peer.id, callId: callId, type: event.type);

      _ringTimeoutTimer?.cancel();
      _ringTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!isClosed && state.callId == callId && state.phase == CallLifecycle.calling) {
          add(EndCall(event.me.id));
        }
      });
    } catch (_) {
      emit(state.copyWith(
        phase: CallLifecycle.failed,
        errorMessage: 'Could not reach the calling server. Check your connection and try again.',
      ));
    }
  }

  Future<void> _onCancelOutgoing(CancelOutgoingCall event, Emitter<CallState> emit) async {
    if (state.peerId == null || state.callId == null) return;
    await _callingService.sendCancel(me: event.me, toUserId: state.peerId!, callId: state.callId!);
    await _finishCall(emit, CallLifecycle.ended, CallStatus.missed, save: true, meId: event.me.id);
  }

  // ---------------- Incoming ----------------

  Future<void> _onAcceptIncoming(AcceptIncomingCall event, Emitter<CallState> emit) async {
    if (state.roomName == null) return;
    emit(state.copyWith(phase: CallLifecycle.connecting, cameraEnabled: state.type == CallType.video));
    try {
      final room = await _callingService.joinCallRoom(roomName: state.roomName!, me: event.me, type: state.type);
      _listenToCallRoom();
      emit(state.copyWith(phase: CallLifecycle.connected, room: room));
      _startDurationTimer();
    } catch (_) {
      emit(state.copyWith(
        phase: CallLifecycle.failed,
        errorMessage: 'Could not join the call. Check your connection and try again.',
      ));
    }
  }

  Future<void> _onDeclineIncoming(DeclineIncomingCall event, Emitter<CallState> emit) async {
    if (state.peerId == null || state.callId == null) return;
    await _callingService.sendReject(me: event.me, toUserId: state.peerId!, callId: state.callId!);
    await _finishCall(emit, CallLifecycle.rejected, CallStatus.rejected, save: true, meId: event.me.id);
  }

  // ---------------- In-call controls ----------------

  Future<void> _onToggleMic(ToggleMicrophone event, Emitter<CallState> emit) async {
    final enabled = !state.micEnabled;
    await _callingService.setMicrophoneEnabled(enabled);
    emit(state.copyWith(micEnabled: enabled));
  }

  Future<void> _onToggleCamera(ToggleCamera event, Emitter<CallState> emit) async {
    final enabled = !state.cameraEnabled;
    await _callingService.setCameraEnabled(enabled);
    emit(state.copyWith(cameraEnabled: enabled));
  }

  Future<void> _onToggleSpeaker(ToggleSpeaker event, Emitter<CallState> emit) async {
    // livekit_client routes audio via the OS by default; this flag mainly
    // drives the UI. Hook into `Hardware.instance.setSpeakerphoneOn` if the
    // installed livekit_client version exposes it, for real speaker toggling.
    emit(state.copyWith(speakerEnabled: !state.speakerEnabled));
  }

  Future<void> _onSwitchCamera(SwitchCamera event, Emitter<CallState> emit) async {
    await _callingService.switchCamera();
  }

  Future<void> _onEndCall(EndCall event, Emitter<CallState> emit) async {
    final wasConnected = state.phase == CallLifecycle.connected;
    await _finishCall(
      emit,
      wasConnected ? CallLifecycle.ended : CallLifecycle.missed,
      wasConnected ? CallStatus.completed : CallStatus.missed,
      save: true,
      meId: event.currentUserId,
    );
  }

  // ---------------- LiveKit room events ----------------

  void _listenToCallRoom() {
    _callRoomEventsSub?.cancel();
    _callRoomEventsSub = _callingService.onCallRoomEvent.listen((event) => add(_CallRoomEventArrived(event)));
  }

  Future<void> _onCallRoomEvent(_CallRoomEventArrived event, Emitter<CallState> emit) async {
    final e = event.event;

    // Peer joined the shared room -> the call is now connected.
    if (e is lk.ParticipantConnectedEvent && state.phase == CallLifecycle.calling) {
      _ringTimeoutTimer?.cancel();
      emit(state.copyWith(phase: CallLifecycle.connected));
      _startDurationTimer();
      return;
    }

    // Peer left the room -> call ends normally.
    if (e is lk.ParticipantDisconnectedEvent && state.phase.isActive) {
      await _finishCall(
        emit,
        CallLifecycle.ended,
        CallStatus.completed,
        save: true,
        meId: _me?.id,
      );
      return;
    }

    // Local network dropped mid-call.
    if (e is lk.RoomDisconnectedEvent && state.phase.isActive) {
      await _finishCall(
        emit,
        CallLifecycle.disconnected,
        CallStatus.failed,
        save: true,
        meId: _me?.id,
        errorMessage: 'Call disconnected — the network connection was lost.',
      );
    }
  }

  // ---------------- Duration timer ----------------

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) => add(const _DurationTick()));
  }

  void _onDurationTick(_DurationTick event, Emitter<CallState> emit) {
    if (state.phase != CallLifecycle.connected) return;
    emit(state.copyWith(duration: state.duration + const Duration(seconds: 1)));
  }

  // ---------------- Shared teardown ----------------

  Future<void> _finishCall(
    Emitter<CallState> emit,
    CallLifecycle phase,
    CallStatus status, {
    bool save = false,
    String? meId,
    String? errorMessage,
  }) async {
    _durationTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    await _callRoomEventsSub?.cancel();
    await _callingService.leaveCallRoom();

    if (save && meId != null && state.callId != null && state.peerId != null && state.direction != null) {
      final call = CallModel(
        callId: state.callId!,
        roomName: state.roomName ?? '',
        peerId: state.peerId!,
        peerName: state.peerName ?? 'Unknown',
        peerAvatarColorHex: state.peerAvatarColorHex ?? '#4F63F6',
        type: state.type,
        direction: state.direction!,
        status: status,
        startedAt: DateTime.now().subtract(state.duration),
        duration: state.duration,
      );
      await _storage.addHistoryEntry(meId, call);
    }

    emit(state.copyWith(phase: phase, errorMessage: errorMessage));
  }

  @override
  Future<void> close() async {
    _durationTimer?.cancel();
    _ringTimeoutTimer?.cancel();
    await _signalSub?.cancel();
    await _callRoomEventsSub?.cancel();
    return super.close();
  }
}
