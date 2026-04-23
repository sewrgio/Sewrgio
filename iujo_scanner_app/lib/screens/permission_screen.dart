/// Pantalla de gestión de permisos con UI premium.
library;

import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/permission_service.dart';
import '../services/secure_storage_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  PermissionState? _permState;
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkPermissions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final state = await PermissionService.checkAll();
    setState(() {
      _permState = state;
      _isLoading = false;
    });
    _animController.forward();
  }

  Future<void> _requestAll() async {
    setState(() => _isLoading = true);
    final state = await PermissionService.requestAll();
    setState(() {
      _permState = state;
      _isLoading = false;
    });

    if (state.criticalGranted && mounted) {
      _navigateToNext();
    }
  }

  Future<void> _navigateToNext() async {
    final hasSession = await SecureStorageService.hasValidSession();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => hasSession ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 1),
                // Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Permisos Requeridos',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Para funcionar correctamente, la app necesita\nacceso a los siguientes servicios:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Permisos
                if (_permState != null) ...[
                  _buildPermissionTile(
                    icon: Icons.camera_alt_rounded,
                    title: 'Cámara',
                    description: 'Para escanear códigos QR de asistencia',
                    granted: _permState!.cameraGranted,
                    onRequest: () async {
                      await PermissionService.requestCamera();
                      _checkPermissions();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionTile(
                    icon: Icons.location_on_rounded,
                    title: 'Ubicación GPS',
                    description:
                        'Para verificar que estás en la universidad',
                    granted: _permState!.locationGranted,
                    onRequest: () async {
                      await PermissionService.requestLocation();
                      _checkPermissions();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notificaciones',
                    description: 'Para alertarte sobre inasistencias',
                    granted: _permState!.notificationGranted,
                    onRequest: () async {
                      await PermissionService.requestNotification();
                      _checkPermissions();
                    },
                  ),
                ],

                const Spacer(flex: 2),

                // Botones
                if (_permState != null && !_permState!.criticalGranted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'CONCEDER PERMISOS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => PermissionService.openSettings(),
                    child: Text(
                      'Abrir configuración del sistema',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                if (_permState != null && _permState!.criticalGranted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _navigateToNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'CONTINUAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted
              ? AppColors.success.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: granted
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: granted ? AppColors.success : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (granted)
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            )
          else
            GestureDetector(
              onTap: onRequest,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Activar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
