/// Servicio de gestión de permisos con UI amigable.
library;

import 'package:permission_handler/permission_handler.dart';

/// Estado de los permisos de la app
class PermissionState {
  final bool cameraGranted;
  final bool locationGranted;
  final bool notificationGranted;

  PermissionState({
    required this.cameraGranted,
    required this.locationGranted,
    required this.notificationGranted,
  });

  bool get allGranted => cameraGranted && locationGranted && notificationGranted;
  bool get criticalGranted => cameraGranted && locationGranted;

  int get grantedCount =>
      (cameraGranted ? 1 : 0) +
      (locationGranted ? 1 : 0) +
      (notificationGranted ? 1 : 0);
}

class PermissionService {
  /// Verificar estado actual de todos los permisos
  static Future<PermissionState> checkAll() async {
    final camera = await Permission.camera.isGranted;
    final location = await Permission.location.isGranted;
    final notification = await Permission.notification.isGranted;

    return PermissionState(
      cameraGranted: camera,
      locationGranted: location,
      notificationGranted: notification,
    );
  }

  /// Solicitar permiso de cámara
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Solicitar permiso de ubicación
  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Solicitar permiso de notificaciones
  static Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Solicitar todos los permisos de una vez
  static Future<PermissionState> requestAll() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
      Permission.notification,
    ].request();

    return PermissionState(
      cameraGranted: statuses[Permission.camera]?.isGranted ?? false,
      locationGranted: statuses[Permission.location]?.isGranted ?? false,
      notificationGranted: statuses[Permission.notification]?.isGranted ?? false,
    );
  }

  /// Verificar si un permiso fue denegado permanentemente
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    return await permission.isPermanentlyDenied;
  }

  /// Abrir configuración de la app para permisos manuales
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
