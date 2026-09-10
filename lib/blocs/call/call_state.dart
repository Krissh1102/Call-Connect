part of 'call_bloc.dart';

class CallState extends Equatable {
  final CallLifecycle phase;
  final String? callId;
  final String? roomName;
  final String? peerId;
  final String? peerName;
  final String? peerAvatarColorHex;
  final CallType type;
  final CallDirection? direction;
  final bool micEnabled;
  final bool cameraEnabled;
  final bool speakerEnabled;
  final Duration duration;
  final String? errorMessage;
  final lk.Room? room; // exposed so screens can attach VideoTrackRenderer widgets

  const CallState({
    this.phase = CallLifecycle.idle,
    this.callId,
    this.roomName,
    this.peerId,
    this.peerName,
    this.peerAvatarColorHex,
    this.type = CallType.audio,
    this.direction,
    this.micEnabled = true,
    this.cameraEnabled = true,
    this.speakerEnabled = true,
    this.duration = Duration.zero,
    this.errorMessage,
    this.room,
  });

  CallState copyWith({
    CallLifecycle? phase,
    String? callId,
    String? roomName,
    String? peerId,
    String? peerName,
    String? peerAvatarColorHex,
    CallType? type,
    CallDirection? direction,
    bool? micEnabled,
    bool? cameraEnabled,
    bool? speakerEnabled,
    Duration? duration,
    String? errorMessage,
    lk.Room? room,
    bool clearError = false,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId ?? this.callId,
      roomName: roomName ?? this.roomName,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerAvatarColorHex: peerAvatarColorHex ?? this.peerAvatarColorHex,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      micEnabled: micEnabled ?? this.micEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      room: room ?? this.room,
    );
  }

  static const idle = CallState();

  @override
  List<Object?> get props => [
        phase,
        callId,
        roomName,
        peerId,
        peerName,
        type,
        direction,
        micEnabled,
        cameraEnabled,
        speakerEnabled,
        duration,
        errorMessage,
      ];
}
