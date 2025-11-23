class SolicitudFertilizanteModel {
  final int idSolicitud;
  final String finca;
  final String ubicacion;
  final String tipoFertilizante;
  final double cantidad;
  final String fechaRequerida;
  final String? fechaSolicitud; // ⭐ NUEVO: Fecha en que se creó la solicitud
  final String motivo;
  final String notas;
  final String prioridad;
  final String estado;
  final int idUsuario;

  SolicitudFertilizanteModel({
    required this.idSolicitud,
    required this.finca,
    required this.ubicacion,
    required this.tipoFertilizante,
    required this.cantidad,
    required this.fechaRequerida,
    this.fechaSolicitud, // ⭐ Campo opcional - se recibe del backend
    required this.motivo,
    required this.notas,
    required this.prioridad,
    required this.estado,
    required this.idUsuario,
  });

  factory SolicitudFertilizanteModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parsear cantidad de forma segura
      double cantidadParsed = 0.0;
      if (json['cantidad'] != null) {
        if (json['cantidad'] is int) {
          cantidadParsed = (json['cantidad'] as int).toDouble();
        } else if (json['cantidad'] is double) {
          cantidadParsed = json['cantidad'];
        } else if (json['cantidad'] is String) {
          cantidadParsed = double.tryParse(json['cantidad']) ?? 0.0;
        }
      }

      // Extraer ID de usuario - maneja múltiples casos
      int userId = 0;
      
      if (json['idUsuario'] != null) {
        userId = json['idUsuario'] is int 
            ? json['idUsuario'] 
            : int.tryParse(json['idUsuario'].toString()) ?? 0;
      } else if (json['usuario'] != null && json['usuario'] is Map) {
        userId = json['usuario']['id'] ?? json['usuario']['idUsuario'] ?? 0;
      } else if (json['usuario_id'] != null) {
        userId = json['usuario_id'] is int
            ? json['usuario_id']
            : int.tryParse(json['usuario_id'].toString()) ?? 0;
      }

      print('🔍 Parseando solicitud #${json['idSolicitud']} -> Usuario ID: $userId');

      return SolicitudFertilizanteModel(
        idSolicitud: json['idSolicitud'] ?? json['id'] ?? 0,
        finca: json['finca']?.toString() ?? 'Sin finca',
        ubicacion: json['ubicacion']?.toString() ?? 'Sin ubicación',
        tipoFertilizante: json['tipoFertilizante']?.toString() ?? 'Sin especificar',
        cantidad: cantidadParsed,
        fechaRequerida: json['fechaRequerida']?.toString() ?? 'Sin fecha',
        fechaSolicitud: json['fechaSolicitud']?.toString(), // ⭐ Se recibe del backend
        motivo: json['motivo']?.toString() ?? '',
        notas: json['notas']?.toString() ?? '',
        prioridad: json['prioridad']?.toString() ?? 'Media',
        estado: json['estado']?.toString() ?? 'PENDIENTE',
        idUsuario: userId,
      );
    } catch (e) {
      print('❌ Error parseando solicitud: $e');
      print('📦 JSON problemático: $json');
      
      return SolicitudFertilizanteModel(
        idSolicitud: 0,
        finca: 'Error',
        ubicacion: 'Error',
        tipoFertilizante: 'Error al cargar',
        cantidad: 0.0,
        fechaRequerida: 'Error',
        fechaSolicitud: null, // ⭐ null en caso de error
        motivo: '',
        notas: '',
        prioridad: 'Media',
        estado: 'ERROR',
        idUsuario: 0,
      );
    }
  }

  // ⭐ Método auxiliar para mostrar la fecha de solicitud formateada
  String get fechaSolicitudFormateada {
    if (fechaSolicitud == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaSolicitud!);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaSolicitud!;
    }
  }

  // Método auxiliar para obtener solo la fecha (sin hora)
  String get fechaSolicitudSoloFecha {
    if (fechaSolicitud == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaSolicitud!);
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (e) {
      return fechaSolicitud!;
    }
  }

  @override
  String toString() {
    return 'Solicitud #$idSolicitud: $tipoFertilizante ($cantidad kg) - $estado [Usuario: $idUsuario] [Creada: ${fechaSolicitudFormateada}]';
  }
}