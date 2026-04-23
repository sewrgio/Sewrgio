/// Modelo de datos para inasistencias
library;

class Inasistencia {
  final String id;
  final String materia;
  final String fecha;
  final String hora;
  final String tipo; // 'falta', 'retardo'
  final String? observacion;
  final bool justificada;

  Inasistencia({
    required this.id,
    required this.materia,
    required this.fecha,
    required this.hora,
    required this.tipo,
    this.observacion,
    this.justificada = false,
  });

  factory Inasistencia.fromJson(Map<String, dynamic> json) {
    return Inasistencia(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      materia: json['materia']?.toString() ?? 'Sin materia',
      fecha: json['fecha']?.toString() ?? '',
      hora: json['hora']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'falta',
      observacion: json['observacion']?.toString(),
      justificada: json['justificada'] == true,
    );
  }

  /// Icono según el tipo de inasistencia
  String get iconEmoji {
    if (justificada) return '📋';
    switch (tipo) {
      case 'retardo':
        return '⏰';
      case 'falta':
      default:
        return '❌';
    }
  }

  /// Color label según estado
  String get estadoLabel {
    if (justificada) return 'Justificada';
    switch (tipo) {
      case 'retardo':
        return 'Retardo';
      case 'falta':
      default:
        return 'Falta';
    }
  }
}
