/// Dashboard principal con ubicación en tiempo real y navegación.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../services/notification_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'login_screen.dart';
import 'scanner_screen.dart';
import 'inasistencias_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ─── Estado ─────────────────────────────────────────
  bool _isLoading = true;
  bool _isInside = false;
  int _scansToday = 0;
  LocationData? _currentLocation;
  String _userName = '';
  String _statusText = 'Conectando GPS...';
  bool _gpsActive = false;
  int _totalInasistencias = 0;

  // ─── Streams y timers ───────────────────────────────
  StreamSubscription<LocationData>? _locationSub;
  Timer? _clockTimer;
  String _horaActual = '';
  String _fechaActual = '';

  // ─── Animaciones ────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    _initDashboard();
  }

  Future<void> _initDashboard() async {
    _updateClock();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateClock(),
    );

    // Cargar nombre del usuario
    final name = await SecureStorageService.getUserName();
    if (mounted && name != null) {
      setState(() => _userName = name);
    }

    // Iniciar tracking GPS
    await LocationService.startTracking();
    _locationSub = LocationService.locationStream.listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _currentLocation = data;
          _gpsActive = true;
          _statusText = data.isInsideRadius
              ? '✅ Dentro del campus — ${data.formattedDistance} del centro'
              : '📍 Fuera del campus — ${data.formattedDistance}';
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _gpsActive = false;
          _statusText = '❌ $error';
        });
      },
    );

    // Cargar estado de asistencia
    await _loadAttendanceStatus();
    await _loadInasistenciasCount();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _horaActual =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _fechaActual = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    });
  }

  Future<void> _loadAttendanceStatus() async {
    final response = await ApiService.getAttendanceStatus();
    if (response.success && mounted) {
      setState(() {
        _isInside = response.data['dentro'] ?? false;
        _scansToday = (response.data['asistenciasHoy'] as List?)?.length ?? 0;
      });
    }
  }

  Future<void> _loadInasistenciasCount() async {
    final response = await ApiService.getInasistencias();
    if (response.success && mounted) {
      final list = response.data['inasistencias'] as List? ?? [];
      setState(() => _totalInasistencias = list.length);

      // Verificar si hay nuevas inasistencias para notificar
      if (list.isNotEmpty) {
        final ultima = list.first;
        final materiaNotif = ultima['materia']?.toString() ?? 'una materia';
        final fechaNotif = ultima['fecha']?.toString() ?? 'hoy';
        // Enviar notificación de la última inasistencia
        await NotificationService.showInasistenciaNotification(
          materia: materiaNotif,
          fecha: fechaNotif,
        );
      }
    }
  }

  Future<void> _startScan() async {
    // Validaciones
    if (_currentLocation != null && !_currentLocation!.isInsideRadius) {
      _showMessage(
        'Debe estar dentro del radio de ${(radioUniversidadMetros / 1000).toStringAsFixed(0)} km de la universidad',
        AppColors.warning,
        Icons.location_off_rounded,
      );
      return;
    }

    if (_scansToday >= maxEscaneosDiarios) {
      _showMessage(
        'Ya realizó sus $maxEscaneosDiarios escaneos permitidos hoy',
        AppColors.warning,
        Icons.block_rounded,
      );
      return;
    }

    final now = DateTime.now();
    if (now.hour < horaInicioEscaneo || now.hour >= horaFinEscaneo) {
      _showMessage(
        'Horario de escaneo: ${horaInicioEscaneo}:00 AM — ${horaFinEscaneo > 12 ? horaFinEscaneo - 12 : horaFinEscaneo}:00 ${horaFinEscaneo >= 12 ? 'PM' : 'AM'}',
        AppColors.warning,
        Icons.schedule_rounded,
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result == true) {
      _loadAttendanceStatus();
    }
  }

  void _showMessage(String message, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureStorageService.clearAll();
      await LocationService.stopTracking();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _clockTimer?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    LocationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInside = _currentLocation?.isInsideRadius ?? false;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Botón de inasistencias
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InasistenciasScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.event_busy_rounded,
                  color: AppColors.warning,
                ),
                tooltip: 'Inasistencias',
              ),
              if (_totalInasistencias > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _totalInasistencias > 99
                          ? '99+'
                          : '$_totalInasistencias',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? const Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.primary,
                    size: 50.0,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadAttendanceStatus();
                    await _loadInasistenciasCount();
                  },
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  Text(
                    _userName.isNotEmpty ? 'Hola, $_userName' : 'Hola de nuevo,',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Panel de Asistencia',
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 24),

                  // ─── GPS en Tiempo Real ─────────────
                  _buildGpsLiveCard(isInside),
                  const SizedBox(height: 16),

                  // ─── Status principal ───────────────
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // ─── Info cards ─────────────────────
                  Row(
                    children: [
                      Expanded(child: _buildMiniCard(
                        Icons.calendar_today_rounded,
                        'Fecha',
                        _fechaActual,
                        AppColors.primary,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniCard(
                        Icons.access_time_rounded,
                        'Hora',
                        _horaActual,
                        AppColors.gold,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMiniCard(
                        Icons.qr_code_scanner_rounded,
                        'Escaneos',
                        '$_scansToday / $maxEscaneosDiarios',
                        AppColors.info,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InasistenciasScreen(),
                            ),
                          ),
                          child: _buildMiniCard(
                            Icons.event_busy_rounded,
                            'Faltas',
                            '$_totalInasistencias',
                            AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ─── Botón de acción ────────────────
                  _buildScanButton(),
                  const SizedBox(height: 16),

                  // ─── Botón ver inasistencias ────────
                  _buildInasistenciasButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────

  Widget _buildGpsLiveCard(bool isInside) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInside
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFF7F1D1D), const Color(0xFF991B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isInside ? AppColors.success : AppColors.error)
                .withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de pulso en vivo
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _gpsActive
                    ? Icons.my_location_rounded
                    : Icons.location_disabled_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _gpsActive
                            ? const Color(0xFF4ADE80)
                            : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _gpsActive ? 'GPS EN VIVO' : 'GPS INACTIVO',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_currentLocation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Radio: ${(radioUniversidadMetros / 1000).toStringAsFixed(0)} km • Distancia: ${_currentLocation!.formattedDistance}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isIn = _currentLocation?.isInsideRadius ?? _isInside;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (isIn ? AppColors.success : AppColors.error)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 44,
              color: isIn ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isIn ? 'DENTRO DEL CAMPUS' : 'FUERA DEL CAMPUS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isIn ? AppColors.success : AppColors.error,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Actualizado: $_horaActual',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final canScan = (_currentLocation?.isInsideRadius ?? false) &&
        _scansToday < maxEscaneosDiarios;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: canScan ? AppColors.primary : AppColors.textMuted,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: canScan ? 4 : 0,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 22),
            SizedBox(width: 12),
            Text(
              'REGISTRAR ASISTENCIA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInasistenciasButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InasistenciasScreen()),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.warning,
          side: const BorderSide(color: AppColors.warning, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'VER MIS FALTAS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
