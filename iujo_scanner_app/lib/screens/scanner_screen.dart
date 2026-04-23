/// Pantalla de escáner QR mejorada con overlay animado.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/constants.dart';
import '../services/api_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLinePosition;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLinePosition = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: AppColors.sidebarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (!_isProcessing) _onDetect(capture);
            },
          ),

          // Overlay oscuro con recorte
          CustomPaint(
            size: size,
            painter: _ScanOverlayPainter(
              scanAreaSize: scanAreaSize,
              borderColor: AppColors.primary,
            ),
          ),

          // Línea de escaneo animada
          if (!_isProcessing)
            Positioned(
              left: (size.width - scanAreaSize) / 2,
              top: (size.height - scanAreaSize) / 2 - 56, // offset por appbar
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: AnimatedBuilder(
                  animation: _scanLinePosition,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          top: _scanLinePosition.value * (scanAreaSize - 4),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0),
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // Esquinas del área de escaneo
          Positioned(
            left: (size.width - scanAreaSize) / 2,
            top: (size.height - scanAreaSize) / 2 - 56,
            child: _buildCorners(scanAreaSize),
          ),

          // Texto de instrucción
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Alinea el código QR en el recuadro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La cámara detectará automáticamente',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Overlay de procesamiento
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpinKitFadingCircle(
                      color: AppColors.primary,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Procesando...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorners(double size) {
    const cornerLength = 30.0;
    const cornerWidth = 4.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(
            top: 0, left: 0,
            child: _corner(cornerLength, cornerWidth, true, true),
          ),
          // Top-right
          Positioned(
            top: 0, right: 0,
            child: _corner(cornerLength, cornerWidth, true, false),
          ),
          // Bottom-left
          Positioned(
            bottom: 0, left: 0,
            child: _corner(cornerLength, cornerWidth, false, true),
          ),
          // Bottom-right
          Positioned(
            bottom: 0, right: 0,
            child: _corner(cornerLength, cornerWidth, false, false),
          ),
        ],
      ),
    );
  }

  Widget _corner(double length, double width, bool isTop, bool isLeft) {
    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          color: AppColors.primary,
          strokeWidth: width,
          isTop: isTop,
          isLeft: isLeft,
        ),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final barcodes = capture.barcodes;
    bool scanned = false;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        await _procesarEscaneo(barcode.rawValue!);
        scanned = true;
        break;
      }
    }

    if (!scanned && mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _procesarEscaneo(String codigo) async {
    final response = await ApiService.scanQR(codigo);

    if (!mounted) return;

    final isSuccess = response.success &&
        (response.data['success'] == true);
    final message = response.message ??
        (isSuccess ? '✅ Asistencia registrada' : '❌ Error al registrar');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );

    // Esperar un momento para que el usuario vea el mensaje
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context, isSuccess);
  }
}

// ─── Painters ───────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  _ScanOverlayPainter({required this.scanAreaSize, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 28),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Dibujar overlay oscuro con recorte transparente
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
          ),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isTop;
  final bool isLeft;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
