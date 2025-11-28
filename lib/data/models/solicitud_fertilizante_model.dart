class SolicitudFertilizanteModel {
  final int idSolicitud;
  final String finca;
  final String ubicacion;
  final String tipoFertilizante;
  final double cantidad;
  final String fechaRequerida;
  final String? fechaSolicitud;
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
    this.fechaSolicitud,
    required this.motivo,
    required this.notas,
    required this.prioridad,
    required this.estado,
    required this.idUsuario,
  });

  factory SolicitudFertilizanteModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 JSON recibido: $json');
      
      // ⭐ CORRECCIÓN 1: Leer ID con snake_case PRIMERO
      int solicitudId = 0;
      if (json['id_solicitud'] != null) {  // ⭐ Backend usa snake_case
        solicitudId = json['id_solicitud'] is int 
            ? json['id_solicitud'] 
            : int.tryParse(json['id_solicitud'].toString()) ?? 0;
      } else if (json['idSolicitud'] != null) {  // Fallback camelCase
        solicitudId = json['idSolicitud'] is int 
            ? json['idSolicitud'] 
            : int.tryParse(json['idSolicitud'].toString()) ?? 0;
      }

      // Parsear cantidad
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

      // ⭐ CORRECCIÓN 2: Leer tipo con snake_case PRIMERO
      String tipoFert = '';
      if (json['tipo_fertilizante'] != null) {  // ⭐ Backend usa snake_case
        tipoFert = json['tipo_fertilizante'].toString();
      } else if (json['tipoFertilizante'] != null) {  // Fallback camelCase
        tipoFert = json['tipoFertilizante'].toString();
      }
      
      if (tipoFert.isEmpty) {
        tipoFert = 'Sin especificar';
      }

      // Extraer ID de usuario
      int userId = 0;
      if (json['idUsuario'] != null) {
        userId = json['idUsuario'] is int 
            ? json['idUsuario'] 
            : int.tryParse(json['idUsuario'].toString()) ?? 0;
      } else if (json['usuario'] != null && json['usuario'] is Map) {
        final usuarioMap = json['usuario'] as Map<String, dynamic>;
        userId = usuarioMap['id'] ?? usuarioMap['idUsuario'] ?? 0;
      }

      print('✅ Solicitud parseada:');
      print('   - ID Solicitud: $solicitudId');
      print('   - Tipo: $tipoFert');
      print('   - Usuario ID: $userId');

      return SolicitudFertilizanteModel(
        idSolicitud: solicitudId,
        finca: json['finca']?.toString() ?? 'Sin finca',
        ubicacion: json['ubicacion']?.toString() ?? 'Sin ubicación',
        tipoFertilizante: tipoFert,
        cantidad: cantidadParsed,
        fechaRequerida: json['fecha_requerida']?.toString() ?? 
                        json['fechaRequerida']?.toString() ?? 
                        'Sin fecha',
        fechaSolicitud: json['fecha_solicitud']?.toString() ?? 
                        json['fechaSolicitud']?.toString(),
        motivo: json['motivo']?.toString() ?? '',
        notas: json['notas']?.toString() ?? '',
        prioridad: json['prioridad']?.toString() ?? 'Media',
        estado: json['estado']?.toString() ?? 'PENDIENTE',
        idUsuario: userId,
      );
    } catch (e, stackTrace) {
      print('❌ Error parseando solicitud: $e');
      print('📦 JSON problemático: $json');
      print('📚 StackTrace: $stackTrace');
      
      return SolicitudFertilizanteModel(
        idSolicitud: 0,
        finca: 'Error',
        ubicacion: 'Error',
        tipoFertilizante: 'Error al cargar',
        cantidad: 0.0,
        fechaRequerida: 'Error',
        fechaSolicitud: null,
        motivo: '',
        notas: '',
        prioridad: 'Media',
        estado: 'ERROR',
        idUsuario: 0,
      );
    }
  }

  // ⭐ Método para convertir a JSON al ACTUALIZAR (usa camelCase porque backend acepta ambos)
  Map<String, dynamic> toJson() {
    return {
      'tipoFertilizante': tipoFertilizante,
      'cantidad': cantidad,
      'fechaRequerida': fechaRequerida,
      'prioridad': prioridad,
      'motivo': motivo,
      'notas': notas,
      'finca': finca,
      'ubicacion': ubicacion,
      'estado': estado,
    };
  }

  String get fechaSolicitudFormateada {
    if (fechaSolicitud == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaSolicitud!);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaSolicitud!;
    }
  }

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
    return 'Solicitud #$idSolicitud: $tipoFertilizante ($cantidad kg) - $estado [Usuario: $idUsuario]';
  }
}