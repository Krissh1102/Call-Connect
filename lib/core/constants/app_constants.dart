/// Central place for app-wide constant values.
///
/// IMPORTANT (read the README "Calling Technology" section):
/// This project uses a *local/mock* backend for the internship assignment,
/// so there is no real signaling server issuing LiveKit access tokens.
/// [TokenService] therefore signs tokens on-device using [livekitApiKey] /
/// [livekitApiSecret] below. This is ONLY safe for local development against
/// a self-hosted `livekit-server --dev` instance — never ship an API secret
/// inside a shipped app. In a production build these values would live on a
/// small server endpoint instead (see README "Known limitations").
class AppConstants {
  AppConstants._();

  static const String appName = 'ConnectCall';
  static const String appTagline = 'Connect with anyone, anywhere.';

  // --- LiveKit (local/dev) ---
  // Defaults match `livekit-server --dev` out of the box.
  static const String livekitUrl = 'ws://10.0.2.2:7880'; // Android emulator -> host machine
  static const String livekitApiKey = 'devkey';
  static const String livekitApiSecret = 'secret';

  // Every signed-in user joins a personal "signal room" named
  // `signal_<uid>` on login. Incoming-call invites are sent as LiveKit
  // data-channel messages into that room, which is how this app implements
  // call signaling without a separate backend.
  static const String signalRoomPrefix = 'signal_';
  static const String callRoomPrefix = 'call_';

  // --- Local storage (mock backend) keys ---
  static const String storeUsers = 'connectcall_users';
  static const String storeSession = 'connectcall_session';
  static const String storeCallHistory = 'connectcall_call_history_';

  // --- Misc ---
  static const Duration ringTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
}
