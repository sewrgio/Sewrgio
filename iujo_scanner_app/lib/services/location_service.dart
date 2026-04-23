/// Servicio de ubicación en tiempo real con geofencing.
/// Provee un Stream reactivo de posición y cálculo de distancia.
library;

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../config/constants.dart';

/// Datos de ubicación procesados
class LocationData {
  final Position position;
  final double distanceMeters;
  final bool isInsideRadius;
  final String formattedDistance;
  final DateTime timestamp;

  LocationData({
    required this.position,
    required this.distanceMeters,
    required this.isInsideRadius,
    required this.formattedDistance,
    required this.timestamp,
  });
}

class LocationService {
  static StreamSubscription<Position>? _positionSubscription;
  static final _locationController = StreamController<LocationData>.broadcast();

  /// Stream reactivo de ubicación procesada
  static Stream<LocationData> get locationStream => _locationController.stream;

  /// Última ubicación conocida
  static LocationData? _lastLocation;
  static LocationData? get lastLocation => _lastLocation;

  /// Verificar si los servicios de ubicación están disponibles
  static Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verificar estado del permiso de ubicación
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Solicitar permiso de ubicación
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Iniciar tracking en tiempo real
  static Future<void> startTracking() async {
    // Verificar servicios
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationController.addError('GPS desactivado');
      return;
    }

    // Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationController.addError('Permiso de ubicación denegado');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationController.addError('Permiso de ubicación denegado permanentemente');
      return;
    }

    // Cancelar tracking anterior si existe
    await stopTracking();

    // Obtener posición inicial
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _processPosition(initialPosition);
    } catch (e) {
      // Continuar con el stream aunque falle la posición inicial
    }

    // Iniciar stream de posición en tiempo real
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros de movimiento
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _processPosition,
      onError: (error) {
        _locationController.addError('Error de GPS: $error');
      },
    );
  }

  /// Procesar una posición y calcular distancia
  static void _processPosition(Position position) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      universityLat,
      universityLng,
    );

    final isInside = distance <= radioUniversidadMetros;
    final formatted = _formatDistance(distance, isInside);

    final locationData = LocationData(
      position: position,
      distanceMeters: distance,
      isInsideRadius: isInside,
      formattedDistance: formatted,
      timestamp: DateTime.now(),
    );

    _lastLocation = locationData;
    _locationController.add(locationData);
  }

  /// Formatear distancia: metros si está dentro, km si está fuera
  static String _formatDistance(double meters, bool isInside) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  /// Obtener posición actual una sola vez
  static Future<LocationData?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        universityLat,
        universityLng,
      );

      final isInside = distance <= radioUniversidadMetros;
      final formatted = _formatDistance(distance, isInside);

      final data = LocationData(
        position: position,
        distanceMeters: distance,
        isInsideRadius: isInside,
        formattedDistance: formatted,
        timestamp: DateTime.now(),
      );

      _lastLocation = data;
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Detener tracking
  static Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Liberar recursos
  static Future<void> dispose() async {
    await stopTracking();
    await _locationController.close();
  }
}
