import 'dart:async';
import 'dart:convert';

import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/call_enums.dart';
import '../models/user_model.dart';
import 'token_service.dart';

/// An invite (or invite-response) delivered over a user's personal signal room.
class SignalMessage {
  final String type; // invite | cancel | reject | busy
  final String callId;
  final String roomName;
  final CallType callType;
  final String fromId;
  final String fromName;
  final String fromAvatarColorHex;

  SignalMessage({
    required this.type,
    required this.callId,
    required this.roomName,
    required this.callType,
    required this.fromId,
    required this.fromName,
    required this.fromAvatarColorHex,
  });

  factory SignalMessage.fromJson(Map<String, dynamic> json) => SignalMessage(
        type: json['type'] as String,
        callId: json['callId'] as String,
        roomName: json['roomName'] as String? ?? '',
        callType: json['callType'] == 'video' ? CallType.video : CallType.audio,
        fromId: json['fromId'] as String,
        fromName: json['fromName'] as String? ?? 'Unknown',
        fromAvatarColorHex: json['fromAvatarColorHex'] as String? ?? '#4F63F6',
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'callId': callId,
        'roomName': roomName,
        'callType': callType == CallType.video ? 'video' : 'audio',
        'fromId': fromId,
        'fromName': fromName,
        'fromAvatarColorHex': fromAvatarColorHex,
      };
}

/// Wraps LiveKit to provide:
///  1. Always-on "signal room" per logged-in user, used purely as a transport
///     for call invites/cancel/reject/busy messages (data-channel JSON).
///  2. The actual per-call media room, with mute/camera/switch-camera/end.
///
/// This is the app's entire "calling technology" integration point — see
/// README "Calling Technology" for why LiveKit + this signaling scheme was
/// chosen for a local/mock-backend assignment.
class CallingService {
  static final _uuid = Uuid();

  lk.Room? _signalRoom;
  lk.Room? _callRoom;
  StreamSubscription? _signalSub;
  StreamSubscription? _callSub;

  final _incomingController = StreamController<SignalMessage>.broadcast();
  final _callRoomEventsController = StreamController<lk.RoomEvent>.broadcast();

  /// Fires when an invite/cancel/reject/busy message arrives on my signal room.
  Stream<SignalMessage> get onSignal => _incomingController.stream;

  /// Fires for every LiveKit event on the currently active call room
  /// (participant joined/left, connection quality, disconnect, etc.).
  Stream<lk.RoomEvent> get onCallRoomEvent => _callRoomEventsController.stream;

  lk.Room? get callRoom => _callRoom;

  // ---------------- Signal room (always-on while logged in) ----------------

  Future<void> startSignaling(UserModel me) async {
    await stopSignaling();
    final roomName = '${AppConstants.signalRoomPrefix}${me.id}';
    final token = TokenService.createAccessToken(identity: me.id, roomName: roomName, name: me.name);

    final room = lk.Room();
    await room.connect(AppConstants.livekitUrl, token, roomOptions: const lk.RoomOptions(adaptiveStream: true));
    _signalRoom = room;

    _signalSub = room.createListener().listen((event) {
      if (event is lk.DataReceivedEvent) {
        try {
          final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
          _incomingController.add(SignalMessage.fromJson(json));
        } catch (_) {
          // Ignore malformed payloads rather than crashing (see README error handling).
        }
      }
    }) as StreamSubscription<dynamic>?;
  }

  Future<void> stopSignaling() async {
    await _signalSub?.cancel();
    await _signalRoom?.disconnect();
    _signalRoom = null;
  }

  /// Briefly joins [toUserId]'s signal room just long enough to publish one
  /// data message, then leaves. This is how invites/cancel/reject/busy are
  /// delivered without a dedicated signaling server.
  Future<void> _sendSignal(String toUserId, SignalMessage message, {required String asUserId, required String asName}) async {
    final roomName = '${AppConstants.signalRoomPrefix}$toUserId';
    final token = TokenService.createAccessToken(identity: asUserId, roomName: roomName, name: asName);
    final room = lk.Room();
    try {
      await room.connect(AppConstants.livekitUrl, token);
      await room.localParticipant?.publishData(
        utf8.encode(jsonEncode(message.toJson())),
        reliable: true,
      );
      // Give the message a moment to flush before tearing the room down.
      await Future.delayed(const Duration(milliseconds: 400));
    } finally {
      await room.disconnect();
    }
  }

  // ---------------- Outgoing call ----------------

  String newCallId() => _uuid.v4();
  String roomNameForCall(String callId) => '${AppConstants.callRoomPrefix}$callId';

  Future<void> sendInvite({
    required UserModel me,
    required String toUserId,
    required String callId,
    required CallType type,
  }) {
    return _sendSignal(
      toUserId,
      SignalMessage(
        type: 'invite',
        callId: callId,
        roomName: roomNameForCall(callId),
        callType: type,
        fromId: me.id,
        fromName: me.name,
        fromAvatarColorHex: me.avatarColorHex,
      ),
      asUserId: me.id,
      asName: me.name,
    );
  }

  Future<void> sendCancel({required UserModel me, required String toUserId, required String callId}) {
    return _sendSignal(
      toUserId,
      SignalMessage(
        type: 'cancel',
        callId: callId,
        roomName: '',
        callType: CallType.audio,
        fromId: me.id,
        fromName: me.name,
        fromAvatarColorHex: me.avatarColorHex,
      ),
      asUserId: me.id,
      asName: me.name,
    );
  }

  Future<void> sendReject({required UserModel me, required String toUserId, required String callId}) {
    return _sendSignal(
      toUserId,
      SignalMessage(
        type: 'reject',
        callId: callId,
        roomName: '',
        callType: CallType.audio,
        fromId: me.id,
        fromName: me.name,
        fromAvatarColorHex: me.avatarColorHex,
      ),
      asUserId: me.id,
      asName: me.name,
    );
  }

  Future<void> sendBusy({required UserModel me, required String toUserId, required String callId}) {
    return _sendSignal(
      toUserId,
      SignalMessage(
        type: 'busy',
        callId: callId,
        roomName: '',
        callType: CallType.audio,
        fromId: me.id,
        fromName: me.name,
        fromAvatarColorHex: me.avatarColorHex,
      ),
      asUserId: me.id,
      asName: me.name,
    );
  }

  // ---------------- Call media room ----------------

  bool get inActiveCall => _callRoom != null;

  Future<lk.Room> joinCallRoom({
    required String roomName,
    required UserModel me,
    required CallType type,
  }) async {
    final token = TokenService.createAccessToken(identity: me.id, roomName: roomName, name: me.name);
    final room = lk.Room();
    await room.connect(AppConstants.livekitUrl, token, roomOptions: const lk.RoomOptions(adaptiveStream: true));
    _callRoom = room;

    _callSub = room.createListener().listen((event) {
      _callRoomEventsController.add(event);
    }) as StreamSubscription<dynamic>?;

    await room.localParticipant?.setMicrophoneEnabled(true);
    if (type == CallType.video) {
      await room.localParticipant?.setCameraEnabled(true);
    }
    return room;
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _callRoom?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> setCameraEnabled(bool enabled) async {
    await _callRoom?.localParticipant?.setCameraEnabled(enabled);
  }

  Future<void> switchCamera() async {
    final pub = _callRoom?.localParticipant?.videoTrackPublications.firstOrNull;
    final track = pub?.track;
    if (track is lk.LocalVideoTrack) {
      await track.switchCamera(lk.CameraPosition.back as String);
    }
  }

  Future<void> leaveCallRoom() async {
    await _callSub?.cancel();
    await _callRoom?.disconnect();
    _callRoom = null;
  }

  void dispose() {
    _incomingController.close();
    _callRoomEventsController.close();
    stopSignaling();
    leaveCallRoom();
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
