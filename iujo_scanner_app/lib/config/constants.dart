/// Configuración central de la aplicación IUJO Scanner
library;

import 'package:flutter/material.dart';

// ─── API ──────────────────────────────────────────────
const String apiUrl = 'http://192.168.123.36:5000/api';
const Duration connectionTimeout = Duration(seconds: 15);

// ─── Geofence ─────────────────────────────────────────
const double universityLat = 10.5102550;
const double universityLng = -66.9369701;
const double radioUniversidadMetros = 1000; // 1 km

// ─── Horario de escaneo ───────────────────────────────
const int horaInicioEscaneo = 7;   // 7:00 AM
const int horaFinEscaneo = 21;     // 9:00 PM
const int maxEscaneosDiarios = 2;

// ─── Colores del sistema (Design Tokens) ──────────────
class AppColors {
  AppColors._();

  // Primarios
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF93C5FD);

  // Acentos
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFCD34D);

  // Fondos
  static const Color sidebarBg = Color(0xFF0F172A);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;

  // Texto
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Bordes
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = primary;

  // Estado
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // GPS
  static const Color insideRadius = Color(0xFF10B981);
  static const Color outsideRadius = Color(0xFFEF4444);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─── Estilos de texto ─────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );
}
