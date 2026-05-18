import 'package:permission_handler/permission_handler.dart';

/// Result returned by [PermissionService.requestCamera].
enum CameraPermissionStatus { granted, denied, permanentlyDenied, restricted }

/// Thin wrapper around permission_handler for camera access.
class PermissionService {
  const PermissionService._();

  /// Requests camera permission and returns a typed status.
  static Future<CameraPermissionStatus> requestCamera() async {
    final status = await Permission.camera.request();
    return _map(status);
  }

  /// Returns the current permission status without prompting the user.
  static Future<CameraPermissionStatus> checkCamera() async {
    final status = await Permission.camera.status;
    return _map(status);
  }

  /// Opens the OS app-settings page so the user can grant permission manually.
  static Future<bool> openSettings() => openAppSettings();

  static CameraPermissionStatus _map(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return CameraPermissionStatus.granted;
      case PermissionStatus.permanentlyDenied:
        return CameraPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return CameraPermissionStatus.restricted;
      default:
        return CameraPermissionStatus.denied;
    }
  }
}
