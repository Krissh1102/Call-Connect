import 'package:permission_handler/permission_handler.dart';

enum PermissionOutcome { granted, denied, permanentlyDenied }

/// Centralizes the three device permissions this app needs, and normalizes
/// the platform's granted/denied/permanently-denied states so the UI can
/// react consistently (see "Permissions" in the assignment).
class PermissionService {
  Future<PermissionOutcome> requestMicrophone() => _request(Permission.microphone);
  Future<PermissionOutcome> requestCamera() => _request(Permission.camera);

  Future<PermissionOutcome> requestForCall(bool needsCamera) async {
    final mic = await requestMicrophone();
    if (mic != PermissionOutcome.granted) return mic;
    if (!needsCamera) return PermissionOutcome.granted;
    return requestCamera();
  }

  Future<PermissionOutcome> _request(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    return PermissionOutcome.denied;
  }

  Future<void> openSettings() => openAppSettings();
}
