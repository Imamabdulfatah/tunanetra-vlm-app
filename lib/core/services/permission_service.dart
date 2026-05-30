import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.contacts,
      Permission.microphone,
      Permission.camera,
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.location,
      Permission.phone,
      Permission.sms,
    ].request();
  }

  Future<bool> requestPermission(Permission permission) async {
    var status = await permission.request();
    return status.isGranted;
  }

  Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
