import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/solicitud_fertilizante_model.dart';

class SolicitudService {
  static final String baseUrl = "https://fertigo-production-0cf0.up.railway.app/solicitudFertilizante";

  Future<List<SolicitudFertilizanteModel>> obtenerSolicitudes() async {
    try {
      print('🔄 Obteniendo solicitudes desde: $baseUrl');
      
      final response = await http.get(
        Uri.parse(baseUrl),
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

  // ==================== OBTENER POR USUARIO ====================
  Future<List<SolicitudFertilizanteModel>> obtenerSolicitudesPorUsuario(int idUsuario) async {
    try {
      print('🔄 Obteniendo solicitudes del usuario #$idUsuario');
      
      final todasLasSolicitudes = await obtenerSolicitudes();
      
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

  // ==================== ELIMINAR SOLICITUD ====================
  Future<void> eliminarSolicitud(int idSolicitud, int idUsuario) async {
    print('🗑️ ============ INICIO ELIMINACIÓN ============');
    print('   📌 ID Solicitud: $idSolicitud');
    print('   📌 ID Usuario: $idUsuario');
    
    final url = Uri.parse('$baseUrl/$idSolicitud/$idUsuario');
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
    
    final url = Uri.parse('$baseUrl/$idSolicitud/$idUsuario');
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
        
        // Parsear la respuesta
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
  }

  // ==================== CREAR SOLICITUD (opcional, si no la tienes) ====================
  Future<SolicitudFertilizanteModel> crearSolicitud(
    int idUsuario,
    SolicitudFertilizanteModel nuevaSolicitud,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/$idUsuario');
      
      final Map<String, dynamic> body = {
        'tipoFertilizante': nuevaSolicitud.tipoFertilizante,
        'cantidad': nuevaSolicitud.cantidad,
        'fechaRequerida': nuevaSolicitud.fechaRequerida,
        'prioridad': nuevaSolicitud.prioridad,
        'motivo': nuevaSolicitud.motivo,
        'notas': nuevaSolicitud.notas,
        'finca': nuevaSolicitud.finca,
        'ubicacion': nuevaSolicitud.ubicacion,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return SolicitudFertilizanteModel.fromJson(jsonResponse);
      } else {
        throw Exception('Error al crear: ${response.body}');
      }
    } catch (e) {
      print('❌ Error creando solicitud: $e');
      rethrow;
    }
  }
}