/// Whether a call carries video or audio only.
enum CallType { audio, video }

/// Direction of a call relative to the current user (for history rows).
enum CallDirection { incoming, outgoing }

/// Lifecycle of an in-progress call, per the assignment's required states:
/// Calling -> Ringing -> Connected -> In Call -> Ended, plus terminal
/// Rejected / Missed / Busy / Failed / Disconnected states.
enum CallLifecycle {
  idle,
  calling, // outgoing: waiting for the callee to answer
  ringing, // incoming: waiting for local user to answer
  connecting, // media/room handshake in progress
  connected, // in call
  ended,
  rejected,
  missed,
  busy,
  failed,
  disconnected,
}

/// Final disposition stored in call history.
enum CallStatus { completed, missed, rejected, failed }

extension CallLifecycleX on CallLifecycle {
  bool get isActive =>
      this == CallLifecycle.calling ||
      this == CallLifecycle.ringing ||
      this == CallLifecycle.connecting ||
      this == CallLifecycle.connected;

  bool get isTerminal => !isActive && this != CallLifecycle.idle;
}
