import 'package:ferti_go/data/models/solicitud_fertilizante.dart';
import 'package:ferti_go/data/models/usuario_sesion.dart';
import 'package:ferti_go/data/services/database_helper.dart';
import 'package:ferti_go/data/services/connectivity_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SolicitudFertilizanteOfflineService {
  static final String baseUrl = "http://192.168.137.34:8080";
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivityService = ConnectivityService();

  // ==================== OBTENER TIPOS DE FERTILIZANTES ====================
  
  Future<List<String>> obtenerTiposFertilizantes() async {
    final hayConexion = await _connectivityService.checkConnection();
    
    if (hayConexion) {
      try {
        print('🌍 Obteniendo fertilizantes desde servidor...');
        final response = await http.get(Uri.parse('$baseUrl/fertilizante'))
            .timeout(const Duration(seconds: 10));
            
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final tipos = data.map((item) => item['nombre'].toString()).toList();
          
          // Guardar en cache
          await _dbHelper.guardarFertilizantesCache(tipos);
          
          print('✅ ${tipos.length} fertilizantes obtenidos y cacheados');
          return tipos;
        }
      } catch (e) {
        print('⚠️ Error obteniendo fertilizantes online: $e');
      }
    }
    
    // Modo offline: usar cache
    print('📱 Usando cache de fertilizantes (modo offline)');
    final cache = await _dbHelper.obtenerFertilizantesCache();
    
    if (cache.isEmpty) {
      throw Exception(
        'Sin conexión y sin datos en cache.\n'
        'Conéctate a internet al menos una vez.'
      );
    }
    
    return cache;
  }

  // ==================== ENVIAR SOLICITUD ====================
  
  Future<Map<String, dynamic>> enviarSolicitud(SolicitudFertilizante solicitud) async {
    final idUsuario = UsuarioSesion.id;
    if (idUsuario == null) {
      throw Exception("Usuario no autenticado");
    }

    final hayConexion = await _connectivityService.checkServerConnection();
    
    if (hayConexion) {
      // ✅ MODO ONLINE: Enviar directamente al servidor
      try {
        print('🌍 Enviando solicitud al servidor...');
        
        final response = await http.post(
          Uri.parse('$baseUrl/solicitudFertilizante/$idUsuario'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(solicitud.toJson()),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Solicitud enviada exitosamente al servidor');
          
          return {
            'exito': true,
            'modo': 'online',
            'mensaje': 'Solicitud enviada correctamente',
          };
        } else {
          throw Exception("Error del servidor: ${response.body}");
        }
      } catch (e) {
        print('⚠️ Error enviando online: $e');
        print('💾 Guardando en cola offline...');
        
        // Si falla online, guardar offline
        return await _guardarSolicitudOffline(solicitud, idUsuario);
      }
    } else {
      // ✅ MODO OFFLINE: Guardar en SQLite para sincronizar después
      print('📱 Sin conexión, guardando solicitud offline...');
      return await _guardarSolicitudOffline(solicitud, idUsuario);
    }
  }

  Future<Map<String, dynamic>> _guardarSolicitudOffline(
    SolicitudFertilizante solicitud,
    int idUsuario,
  ) async {
    final idLocal = await _dbHelper.guardarSolicitudPendiente({
      'idUsuario': idUsuario,
      'tipoFertilizante': solicitud.tipoFertilizante,
      'cantidad': solicitud.cantidad,
      'fechaRequerida': solicitud.fechaRequerida,
      'prioridad': solicitud.prioridad,
      'motivo': solicitud.motivo,
      'notas': solicitud.notas,
      'finca': solicitud.finca ?? '',
      'ubicacion': solicitud.ubicacion ?? '',
      'estado': 'PENDIENTE',
    });

    return {
      'exito': true,
      'modo': 'offline',
      'idLocal': idLocal,
      'mensaje': 'Solicitud guardada localmente. Se sincronizará cuando haya conexión.',
    };
  }

  // ==================== SINCRONIZAR SOLICITUDES PENDIENTES ====================
  
  Future<Map<String, dynamic>> sincronizarSolicitudesPendientes() async {
    print('\n🔄 ============ SINCRONIZACIÓN ============');
    
    final hayConexion = await _connectivityService.checkServerConnection();
    
    if (!hayConexion) {
      print('   ❌ Sin conexión, sincronización cancelada');
      return {
        'exito': false,
        'mensaje': 'Sin conexión a internet',
      };
    }

    final idUsuario = UsuarioSesion.id;
    if (idUsuario == null) {
      return {
        'exito': false,
        'mensaje': 'Usuario no autenticado',
      };
    }

    final pendientes = await _dbHelper.obtenerSolicitudesPendientes(idUsuario);
    print('   📦 Solicitudes pendientes: ${pendientes.length}');

    if (pendientes.isEmpty) {
      print('   ✅ No hay solicitudes pendientes');
      return {
        'exito': true,
        'sincronizadas': 0,
        'mensaje': 'No hay solicitudes pendientes',
      };
    }

    int exitosas = 0;
    int fallidas = 0;

    for (var solicitudLocal in pendientes) {
      try {
        print('   🔃 Sincronizando solicitud local #${solicitudLocal['id']}...');
        
        final solicitud = SolicitudFertilizante(
          tipoFertilizante: solicitudLocal['tipoFertilizante'],
          cantidad: solicitudLocal['cantidad'],
          fechaRequerida: solicitudLocal['fechaRequerida'],
          prioridad: solicitudLocal['prioridad'],
          motivo: solicitudLocal['motivo'] ?? '',
          notas: solicitudLocal['notas'] ?? '',
        );

        final response = await http.post(
          Uri.parse('$baseUrl/solicitudFertilizante/$idUsuario'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(solicitud.toJson()),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _dbHelper.marcarComoSincronizado(solicitudLocal['id']);
          exitosas++;
          print('   ✅ Solicitud #${solicitudLocal['id']} sincronizada');
        } else {
          fallidas++;
          print('   ❌ Error sincronizando #${solicitudLocal['id']}: ${response.body}');
        }
      } catch (e) {
        fallidas++;
        print('   ❌ Excepción sincronizando #${solicitudLocal['id']}: $e');
      }
    }

    print('   📊 Resultado: $exitosas exitosas, $fallidas fallidas');
    print('🔄 ============ FIN SINCRONIZACIÓN ============\n');

    return {
      'exito': exitosas > 0,
      'sincronizadas': exitosas,
      'fallidas': fallidas,
      'mensaje': '$exitosas de ${pendientes.length} solicitudes sincronizadas',
    };
  }

  // ==================== OBTENER SOLICITUDES PENDIENTES LOCALES ====================
  
  Future<int> contarSolicitudesPendientes() async {
    final idUsuario = UsuarioSesion.id;
    if (idUsuario == null) return 0;
    
    final pendientes = await _dbHelper.obtenerSolicitudesPendientes(idUsuario);
    return pendientes.length;
  }
}