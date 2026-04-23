/// Servicio HTTP centralizado con autenticación y manejo de errores.
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'secure_storage_service.dart';

/// Respuesta procesada del API
class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> data;
  final bool success;
  final String? message;

  ApiResponse({
    required this.statusCode,
    required this.data,
    required this.success,
    this.message,
  });
}

class ApiService {
  /// Headers base con autenticación
  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await SecureStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// GET request autenticado
  static Future<ApiResponse> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiUrl$endpoint'),
            headers: await _getHeaders(),
          )
          .timeout(connectionTimeout);

      return _processResponse(response);
    } on TimeoutException {
      return ApiResponse(
        statusCode: 408,
        data: {},
        success: false,
        message: 'Tiempo de espera agotado',
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        data: {},
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// POST request autenticado
  static Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl$endpoint'),
            headers: await _getHeaders(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(connectionTimeout);

      return _processResponse(response);
    } on TimeoutException {
      return ApiResponse(
        statusCode: 408,
        data: {},
        success: false,
        message: 'Tiempo de espera agotado',
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        data: {},
        success: false,
        message: 'Error de conexión',
      );
    }
  }

  /// Procesar respuesta HTTP
  static ApiResponse _processResponse(http.Response response) {
    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = {'raw': response.body};
    }

    return ApiResponse(
      statusCode: response.statusCode,
      data: data,
      success: response.statusCode >= 200 && response.statusCode < 300,
      message: data['message']?.toString(),
    );
  }

  // ─── Endpoints específicos ──────────────────────────

  /// Login
  static Future<ApiResponse> login(String email, String password) async {
    return await post(
      '/auth/login',
      {'correo': email, 'password': password},
      withAuth: false,
    );
  }

  /// Estado de asistencia
  static Future<ApiResponse> getAttendanceStatus() async {
    return await get('/asistencias/estado');
  }

  /// Escanear QR
  static Future<ApiResponse> scanQR(String code) async {
    return await post('/asistencias/escanear', {'codigo_qr': code});
  }

  /// Obtener inasistencias del profesor
  static Future<ApiResponse> getInasistencias() async {
    return await get('/asistencias/inasistencias');
  }

  /// Obtener inasistencias filtradas por fecha
  static Future<ApiResponse> getInasistenciasByDate(
    String startDate,
    String endDate,
  ) async {
    return await get(
      '/asistencias/inasistencias?desde=$startDate&hasta=$endDate',
    );
  }
}
