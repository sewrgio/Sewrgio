/// Pantalla de Inasistencias — vista para el profesor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/constants.dart';
import '../models/inasistencia_model.dart';
import '../services/api_service.dart';

class InasistenciasScreen extends StatefulWidget {
  const InasistenciasScreen({super.key});

  @override
  State<InasistenciasScreen> createState() => _InasistenciasScreenState();
}

class _InasistenciasScreenState extends State<InasistenciasScreen>
    with SingleTickerProviderStateMixin {
  List<Inasistencia> _inasistencias = [];
  List<Inasistencia> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Todas';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadInasistencias();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadInasistencias() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.getInasistencias();

    if (!mounted) return;

    if (response.success) {
      final list = response.data['inasistencias'] as List? ?? [];
      setState(() {
        _inasistencias =
            list.map((e) => Inasistencia.fromJson(e as Map<String, dynamic>)).toList();
        _applyFilter();
        _isLoading = false;
      });
      _animController.forward();
    } else {
      setState(() {
        _error = response.message ?? 'Error al cargar inasistencias';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case 'Faltas':
        _filtered = _inasistencias
            .where((e) => e.tipo == 'falta' && !e.justificada)
            .toList();
        break;
      case 'Retardos':
        _filtered =
            _inasistencias.where((e) => e.tipo == 'retardo').toList();
        break;
      case 'Justificadas':
        _filtered =
            _inasistencias.where((e) => e.justificada).toList();
        break;
      default:
        _filtered = List.from(_inasistencias);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estadísticas
    final totalFaltas =
        _inasistencias.where((e) => e.tipo == 'falta' && !e.justificada).length;
    final totalRetardos =
        _inasistencias.where((e) => e.tipo == 'retardo').length;
    final totalJustificadas =
        _inasistencias.where((e) => e.justificada).length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Inasistencias',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadInasistencias,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Actualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitFadingCircle(color: AppColors.primary, size: 40),
            )
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadInasistencias,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Resumen ────────────────────
                        const Text(
                          'Resumen',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                '${_inasistencias.length}',
                                'Total',
                                AppColors.primary,
                                Icons.event_note_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                '$totalFaltas',
                                'Faltas',
                                AppColors.error,
                                Icons.cancel_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                '$totalRetardos',
                                'Retardos',
                                AppColors.warning,
                                Icons.access_time_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                '$totalJustificadas',
                                'Justif.',
                                AppColors.success,
                                Icons.check_circle_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ─── Filtros ────────────────────
                        const Text(
                          'Filtrar por',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'Todas',
                              'Faltas',
                              'Retardos',
                              'Justificadas',
                            ].map((filter) {
                              final isSelected = _selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(filter),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedFilter = filter;
                                      _applyFilter();
                                    });
                                  },
                                  selectedColor: AppColors.primary,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  showCheckmark: false,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ─── Lista ──────────────────────
                        Text(
                          'Registros (${_filtered.length})',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 12),

                        if (_filtered.isEmpty)
                          _buildEmptyState()
                        else
                          ..._filtered.asMap().entries.map((entry) {
                            return _buildInasistenciaCard(
                              entry.value,
                              entry.key,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInasistenciaCard(Inasistencia item, int index) {
    Color typeColor;
    IconData typeIcon;

    if (item.justificada) {
      typeColor = AppColors.success;
      typeIcon = Icons.check_circle_rounded;
    } else if (item.tipo == 'retardo') {
      typeColor = AppColors.warning;
      typeIcon = Icons.access_time_rounded;
    } else {
      typeColor = AppColors.error;
      typeIcon = Icons.cancel_rounded;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono de tipo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.materia,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        item.fecha,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        item.hora,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (item.observacion != null &&
                      item.observacion!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.observacion!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Badge de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.estadoLabel,
                style: TextStyle(
                  color: typeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Sin registros!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'Todas'
                ? 'No tienes inasistencias registradas'
                : 'No hay registros para este filtro',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Error desconocido',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadInasistencias,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
