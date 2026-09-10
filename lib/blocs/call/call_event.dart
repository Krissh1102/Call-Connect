part of 'call_bloc.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

/// Start listening for incoming calls; call once right after login.
class StartListeningForCalls extends CallEvent {
  final UserModel me;
  const StartListeningForCalls(this.me);
  @override
  List<Object?> get props => [me];
}

class StopListeningForCalls extends CallEvent {
  const StopListeningForCalls();
}

/// Internal: a signal (invite/cancel/reject/busy) arrived on the signal room.
class _SignalArrived extends CallEvent {
  final SignalMessage message;
  const _SignalArrived(this.message);
  @override
  List<Object?> get props => [message];
}

class PlaceCall extends CallEvent {
  final UserModel me;
  final UserModel peer;
  final CallType type;
  const PlaceCall({required this.me, required this.peer, required this.type});
  @override
  List<Object?> get props => [me, peer, type];
}

class CancelOutgoingCall extends CallEvent {
  final UserModel me;
  const CancelOutgoingCall(this.me);
  @override
  List<Object?> get props => [me];
}

class AcceptIncomingCall extends CallEvent {
  final UserModel me;
  const AcceptIncomingCall(this.me);
  @override
  List<Object?> get props => [me];
}

class DeclineIncomingCall extends CallEvent {
  final UserModel me;
  const DeclineIncomingCall(this.me);
  @override
  List<Object?> get props => [me];
}

class ToggleMicrophone extends CallEvent {
  const ToggleMicrophone();
}

class ToggleCamera extends CallEvent {
  const ToggleCamera();
}

class ToggleSpeaker extends CallEvent {
  const ToggleSpeaker();
}

class SwitchCamera extends CallEvent {
  const SwitchCamera();
}

class EndCall extends CallEvent {
  final String currentUserId;
  const EndCall(this.currentUserId);
  @override
  List<Object?> get props => [currentUserId];
}

/// Internal: raw LiveKit event on the active call room.
class _CallRoomEventArrived extends CallEvent {
  final lk.RoomEvent event;
  const _CallRoomEventArrived(this.event);
  @override
  List<Object?> get props => [event];
}

/// Internal: 1-second duration tick while connected.
class _DurationTick extends CallEvent {
  const _DurationTick();
}

class ClearCallError extends CallEvent {
  const ClearCallError();
}

class ResetCall extends CallEvent {
  const ResetCall();
}
