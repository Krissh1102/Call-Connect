import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/constants/app_constants.dart';

/// Generates LiveKit access tokens (JWTs) entirely on-device.
///
/// This exists purely so the assignment's "simple backend is sufficient"
/// requirement can be met without standing up a server: it hand-signs a
/// LiveKit-compatible JWT using [AppConstants.livekitApiSecret]. This is
/// explicitly a *local/dev-only* shortcut — see README "Known limitations"
/// for how this would be replaced by a tiny server endpoint in production
/// (the client would call it over HTTPS instead of holding the secret).
class TokenService {
  static String createAccessToken({
    required String identity,
    required String roomName,
    required String name,
    Duration ttl = const Duration(hours: 6),
  }) {
    final now = DateTime.now().toUtc();
    final iat = now.millisecondsSinceEpoch ~/ 1000;
    final exp = now.add(ttl).millisecondsSinceEpoch ~/ 1000;

    final header = {'alg': 'HS256', 'typ': 'JWT'};
    final payload = {
      'iss': AppConstants.livekitApiKey,
      'sub': identity,
      'iat': iat,
      'nbf': iat,
      'exp': exp,
      'name': name,
      'video': {
        'room': roomName,
        'roomJoin': true,
        'canPublish': true,
        'canSubscribe': true,
        'canPublishData': true,
      },
    };

    final headerB64 = _b64UrlEncode(jsonEncode(header));
    final payloadB64 = _b64UrlEncode(jsonEncode(payload));
    final signingInput = '$headerB64.$payloadB64';

    final hmac = Hmac(sha256, utf8.encode(AppConstants.livekitApiSecret));
    final signature = hmac.convert(utf8.encode(signingInput));
    final signatureB64 = _b64UrlEncodeBytes(signature.bytes);

    return '$signingInput.$signatureB64';
  }

  static String _b64UrlEncode(String input) => _b64UrlEncodeBytes(utf8.encode(input));

  static String _b64UrlEncodeBytes(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
