class SolicitudFertilizanteModel {
  final int idSolicitud;
  final String finca;
  final String ubicacion;
  final String tipoFertilizante;
  final double cantidad;
  final String fechaRequerida;
  final String motivo;
  final String notas;
  final String prioridad;
  final String estado;
  final int idUsuario; // ✅ Ya no es nullable

  SolicitudFertilizanteModel({
    required this.idSolicitud,
    required this.finca,
    required this.ubicacion,
    required this.tipoFertilizante,
    required this.cantidad,
    required this.fechaRequerida,
    required this.motivo,
    required this.notas,
    required this.prioridad,
    required this.estado,
    required this.idUsuario, // ✅ Ahora es requerido
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

      // ✅ Extraer ID de usuario - maneja múltiples casos
      int userId = 0;
      
      // Caso 1: idUsuario directo en el JSON
      if (json['idUsuario'] != null) {
        userId = json['idUsuario'] is int 
            ? json['idUsuario'] 
            : int.tryParse(json['idUsuario'].toString()) ?? 0;
      } 
      // Caso 2: objeto usuario anidado con id
      else if (json['usuario'] != null && json['usuario'] is Map) {
        userId = json['usuario']['id'] ?? json['usuario']['idUsuario'] ?? 0;
      }
      // Caso 3: usuario_id (snake_case)
      else if (json['usuario_id'] != null) {
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
        motivo: json['motivo']?.toString() ?? '',
        notas: json['notas']?.toString() ?? '',
        prioridad: json['prioridad']?.toString() ?? 'Media',
        estado: json['estado']?.toString() ?? 'PENDIENTE',
        idUsuario: userId,
      );
    } catch (e) {
      print('❌ Error parseando solicitud: $e');
      print('📦 JSON problemático: $json');
      
      // ✅ Incluso en error, devolvemos un idUsuario válido
      return SolicitudFertilizanteModel(
        idSolicitud: 0,
        finca: 'Error',
        ubicacion: 'Error',
        tipoFertilizante: 'Error al cargar',
        cantidad: 0.0,
        fechaRequerida: 'Error',
        motivo: '',
        notas: '',
        prioridad: 'Media',
        estado: 'ERROR',
        idUsuario: 0, // ✅ Valor por defecto en caso de error
      );
    }
  }

  @override
  String toString() {
    return 'Solicitud #$idSolicitud: $tipoFertilizante ($cantidad kg) - $estado [Usuario: $idUsuario]';
  }
}