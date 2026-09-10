import 'package:equatable/equatable.dart';
import '../core/utils/call_enums.dart';

/// A single call-history entry, and also the live payload passed to the
/// audio/video call screens while a call is in progress.
class CallModel extends Equatable {
  final String callId;
  final String roomName;
  final String peerId;
  final String peerName;
  final String peerAvatarColorHex;
  final CallType type;
  final CallDirection direction;
  final CallStatus? status; // null while the call is still active
  final DateTime startedAt;
  final Duration duration;

  const CallModel({
    required this.callId,
    required this.roomName,
    required this.peerId,
    required this.peerName,
    required this.peerAvatarColorHex,
    required this.type,
    required this.direction,
    this.status,
    required this.startedAt,
    this.duration = Duration.zero,
  });

  CallModel copyWith({
    CallStatus? status,
    Duration? duration,
  }) {
    return CallModel(
      callId: callId,
      roomName: roomName,
      peerId: peerId,
      peerName: peerName,
      peerAvatarColorHex: peerAvatarColorHex,
      type: type,
      direction: direction,
      status: status ?? this.status,
      startedAt: startedAt,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'roomName': roomName,
        'peerId': peerId,
        'peerName': peerName,
        'peerAvatarColorHex': peerAvatarColorHex,
        'type': type.name,
        'direction': direction.name,
        'status': status?.name,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': duration.inSeconds,
      };

  factory CallModel.fromJson(Map<String, dynamic> json) => CallModel(
        callId: json['callId'] as String,
        roomName: json['roomName'] as String,
        peerId: json['peerId'] as String,
        peerName: json['peerName'] as String,
        peerAvatarColorHex: json['peerAvatarColorHex'] as String? ?? '#4F63F6',
        type: CallType.values.byName(json['type'] as String),
        direction: CallDirection.values.byName(json['direction'] as String),
        status: json['status'] != null ? CallStatus.values.byName(json['status'] as String) : null,
        startedAt: DateTime.parse(json['startedAt'] as String),
        duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      );

  @override
  List<Object?> get props => [callId, roomName, peerId, type, direction, status, startedAt, duration];
}
