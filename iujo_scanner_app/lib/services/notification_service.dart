/// Servicio de notificaciones locales para alertar sobre inasistencias.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const channel = AndroidNotificationChannel(
      'inasistencias_channel',
      'Inasistencias',
      description: 'Notificaciones de inasistencias registradas',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Callback cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    // Se puede manejar navegación aquí
    debugPrint('Notificación tocada: ${response.payload}');
  }

  /// Mostrar notificación de inasistencia
  static Future<void> showInasistenciaNotification({
    required String materia,
    required String fecha,
    String? detalle,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'inasistencias_channel',
      'Inasistencias',
      channelDescription: 'Notificaciones de inasistencias registradas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFEF4444),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '⚠️ Inasistencia Registrada',
      'Se registró una falta en $materia el $fecha${detalle != null ? '. $detalle' : ''}',
      details,
      payload: 'inasistencia_$materia',
    );
  }

  /// Mostrar notificación genérica
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'inasistencias_channel',
      'Inasistencias',
      channelDescription: 'Notificaciones de la app IUJO',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancelar todas las notificaciones
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
