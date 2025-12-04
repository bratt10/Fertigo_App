import 'package:ferti_go/data/models/solicitud_fertilizante.dart';
import 'package:ferti_go/data/models/solicitud_fertilizante_model.dart'; // ⭐ Importar el modelo correcto
import 'package:ferti_go/data/models/usuario_sesion.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SolicitudFertilizanteService {
  static final String baseUrl = "https://fertigo-production-0cf0.up.railway.app";

  // ==================== OBTENER TIPOS DE FERTILIZANTES ====================
  Future<List<String>> obtenerTiposFertilizantes() async {
    final response = await http.get(Uri.parse('$baseUrl/fertilizante'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['nombre'].toString()).toList();
    } else {
      throw Exception("Error al cargar fertilizantes");
    }
  }

  // ==================== ENVIAR SOLICITUD ====================
  // ⭐ Usa SolicitudFertilizante (sin IDs) para enviar
  Future<void> enviarSolicitud(SolicitudFertilizante solicitud) async {
    final idUsuario = UsuarioSesion.id;
    if (idUsuario == null) throw Exception("Usuario no autenticado");

    final response = await http.post(
      Uri.parse('$baseUrl/solicitudFertilizante/$idUsuario'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(solicitud.toJson()), // No incluye fechaSolicitud
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al enviar solicitud: ${response.body}");
    }
  }

  // ==================== OBTENER TODAS LAS SOLICITUDES ====================
  // ⭐ Usa SolicitudFertilizanteModel (con IDs) para recibir
  Future<List<SolicitudFertilizanteModel>> obtenerTodasLasSolicitudes() async {
    try {
      print('🔄 Obteniendo todas las solicitudes desde: $baseUrl/solicitudFertilizante');
      
      final response = await http.get(
        Uri.parse('$baseUrl/solicitudFertilizante'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor tardó demasiado en responder');
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print('✅ Total de solicitudes recibidas: ${jsonData.length}');
        
        List<SolicitudFertilizanteModel> solicitudes = [];
        
        for (int i = 0; i < jsonData.length; i++) {
          try {
            var solicitud = SolicitudFertilizanteModel.fromJson(jsonData[i]);
            solicitudes.add(solicitud);
          } catch (e) {
            print('⚠️ Error parseando solicitud $i: $e');
          }
        }
        
        print('🎉 ${solicitudes.length} solicitudes cargadas correctamente');
        return solicitudes;
        
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException catch (_) {
      print('❌ Sin conexión al servidor en: $baseUrl');
      throw Exception('No se puede conectar al servidor. Verifica tu conexión.');
    } on FormatException catch (_) {
      print('❌ Respuesta inválida del servidor');
      throw Exception('El servidor envió una respuesta inválida');
    } catch (e) {
      print('❌ Error general: $e');
      rethrow;
    }
  }

  // ==================== OBTENER SOLICITUDES POR USUARIO ====================
  Future<List<SolicitudFertilizanteModel>> obtenerSolicitudesPorUsuario(int idUsuario) async {
    try {
      print('🔄 Obteniendo solicitudes del usuario #$idUsuario');
      
      final todasLasSolicitudes = await obtenerTodasLasSolicitudes();
      
      final solicitudesDelUsuario = todasLasSolicitudes
          .where((s) => s.idUsuario == idUsuario)
          .toList();
      
      print('✅ Usuario #$idUsuario tiene ${solicitudesDelUsuario.length} solicitudes');
      return solicitudesDelUsuario;
      
    } catch (e) {
      print('❌ Error obteniendo solicitudes del usuario: $e');
      rethrow;
    }
  }

  // ==================== APLICAR FILTROS ====================
  List<SolicitudFertilizanteModel> aplicarFiltros(
    List<SolicitudFertilizanteModel> solicitudes, {
    String? filtroEstado,
    String? filtroFechaSolicitud, // Cuándo se creó la solicitud
    String? filtroFechaRequerida, // Cuándo necesitan el fertilizante
  }) {
    List<SolicitudFertilizanteModel> resultado = List.from(solicitudes);
    
    // Filtro por estado
    if (filtroEstado != null && filtroEstado != 'TODAS') {
      resultado = resultado
          .where((s) => s.estado.toUpperCase() == filtroEstado)
          .toList();
    }
    
    // Filtro por fecha de solicitud (cuando se creó)
    if (filtroFechaSolicitud != null && filtroFechaSolicitud != 'TODAS') {
      final ahora = DateTime.now();
      resultado = resultado.where((s) {
        if (s.fechaSolicitud == null) return false;
        
        try {
          final fechaSolicitud = DateTime.parse(s.fechaSolicitud!);
          
          switch (filtroFechaSolicitud) {
            case 'HOY':
              return fechaSolicitud.year == ahora.year &&
                     fechaSolicitud.month == ahora.month &&
                     fechaSolicitud.day == ahora.day;
            
            case 'ESTA_SEMANA':
              final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
              final finSemana = inicioSemana.add(const Duration(days: 6));
              return fechaSolicitud.isAfter(inicioSemana.subtract(const Duration(days: 1))) &&
                     fechaSolicitud.isBefore(finSemana.add(const Duration(days: 1)));
            
            case 'ESTE_MES':
              return fechaSolicitud.year == ahora.year &&
                     fechaSolicitud.month == ahora.month;
            
            case 'ULTIMOS_7_DIAS':
              final hace7Dias = ahora.subtract(const Duration(days: 7));
              return fechaSolicitud.isAfter(hace7Dias);
            
            case 'ULTIMOS_30_DIAS':
              final hace30Dias = ahora.subtract(const Duration(days: 30));
              return fechaSolicitud.isAfter(hace30Dias);
            
            default:
              return true;
          }
        } catch (e) {
          print('⚠️ Error parseando fechaSolicitud: $e');
          return false;
        }
      }).toList();
    }
    
    // Filtro por fecha requerida (cuando necesitan el fertilizante)
    if (filtroFechaRequerida != null && filtroFechaRequerida != 'TODAS') {
      final ahora = DateTime.now();
      resultado = resultado.where((s) {
        try {
          final fechaRequerida = DateTime.parse(s.fechaRequerida);
          
          switch (filtroFechaRequerida) {
            case 'HOY':
              return fechaRequerida.year == ahora.year &&
                     fechaRequerida.month == ahora.month &&
                     fechaRequerida.day == ahora.day;
            
            case 'ESTA_SEMANA':
              final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
              final finSemana = inicioSemana.add(const Duration(days: 6));
              return fechaRequerida.isAfter(inicioSemana.subtract(const Duration(days: 1))) &&
                     fechaRequerida.isBefore(finSemana.add(const Duration(days: 1)));
            
            case 'ESTE_MES':
              return fechaRequerida.year == ahora.year &&
                     fechaRequerida.month == ahora.month;
            
            case 'PROXIMAS':
              return fechaRequerida.isAfter(ahora);
            
            case 'PASADAS':
              return fechaRequerida.isBefore(ahora);
            
            default:
              return true;
          }
        } catch (e) {
          print('⚠️ Error parseando fechaRequerida: $e');
          return false;
        }
      }).toList();
    }
    
    return resultado;
  }

  // ==================== ELIMINAR SOLICITUD ====================
  Future<void> eliminarSolicitud(int idSolicitud, int idUsuario) async {
    print('🗑️ ============ INICIO ELIMINACIÓN ============');
    print('   📌 ID Solicitud: $idSolicitud');
    print('   📌 ID Usuario: $idUsuario');
    
    final url = Uri.parse('$baseUrl/solicitudFertilizante/$idSolicitud/$idUsuario');
    print('   🌐 URL completa: $url');

    try {
      final response = await http.delete(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al eliminar');
        },
      );
      
      print('   📡 Status Code: ${response.statusCode}');
      print('   📦 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('   ✅ Eliminación exitosa en servidor');
      } else {
        print('   ❌ Error del servidor: ${response.statusCode}');
        throw Exception('Error al eliminar: ${response.body}');
      }
    } catch (e) {
      print('   💥 EXCEPCIÓN: $e');
      rethrow;
    } finally {
      print('🗑️ ============ FIN ELIMINACIÓN ============\n');
    }
  }

  // ==================== ACTUALIZAR SOLICITUD ====================
  Future<SolicitudFertilizanteModel> actualizarSolicitud(
    int idSolicitud,
    int idUsuario,
    SolicitudFertilizanteModel solicitudActualizada,
  ) async {
    print('📝 ============ INICIO ACTUALIZACIÓN ============');
    print('   📌 ID Solicitud: $idSolicitud');
    print('   📌 ID Usuario: $idUsuario');
    
    final url = Uri.parse('$baseUrl/solicitudFertilizante/$idSolicitud/$idUsuario');
    print('   🌐 URL completa: $url');

    try {
      // Convertir modelo a JSON
      final Map<String, dynamic> body = {
        'tipoFertilizante': solicitudActualizada.tipoFertilizante,
        'cantidad': solicitudActualizada.cantidad,
        'fechaRequerida': solicitudActualizada.fechaRequerida,
        'prioridad': solicitudActualizada.prioridad,
        'motivo': solicitudActualizada.motivo,
        'notas': solicitudActualizada.notas,
        'finca': solicitudActualizada.finca,
        'ubicacion': solicitudActualizada.ubicacion,
        'estado': solicitudActualizada.estado,
        // ⚠️ NO enviar fechaSolicitud - no se debe modificar
      };

      print('   📤 Datos enviados: ${json.encode(body)}');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al actualizar');
        },
      );
      
      print('   📡 Status Code: ${response.statusCode}');
      print('   📦 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('   ✅ Actualización exitosa en servidor');
        
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return SolicitudFertilizanteModel.fromJson(jsonResponse);
      } else {
        print('   ❌ Error del servidor: ${response.statusCode}');
        throw Exception('Error al actualizar: ${response.body}');
      }
    } catch (e) {
      print('   💥 EXCEPCIÓN: $e');
      rethrow;
    } finally {
      print('📝 ============ FIN ACTUALIZACIÓN ============\n');
    }
  } //prueba github
}