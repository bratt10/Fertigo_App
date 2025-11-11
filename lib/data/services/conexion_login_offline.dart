import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ferti_go/data/models/usuario_sesion.dart';
import 'package:ferti_go/data/services/database_helper.dart';
import 'package:ferti_go/data/services/connectivity_service.dart';

class ConexionLoginOffline {
  static final String baseUrl = 'http://192.168.137.34:8080/app';
  static final DatabaseHelper _dbHelper = DatabaseHelper();
  static final ConnectivityService _connectivityService = ConnectivityService();

  /// Login principal: intenta online primero, luego offline
  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('\n🔐 ============ INICIO DE LOGIN ============');
    print('   📧 Email: $email');
    
    // 1. Verificar conexión
    final hayConexion = await _connectivityService.checkConnection();
    print('   🌐 Conexión disponible: $hayConexion');

    if (hayConexion) {
      // ✅ MODO ONLINE
      print('   🌍 Intentando login ONLINE...');
      try {
        final data = await _loginOnline(email, password);
        
        // ✅ Guardar usuario en SQLite INMEDIATAMENTE después de login exitoso
        print('   💾 Guardando usuario en SQLite para uso offline...');
        await _dbHelper.guardarUsuario({
          ...data,
          'contraseña': password, // Guardar para validación offline
        });
        
        UsuarioSesion.guardarUsuario(data);
        print('   ✅ Login ONLINE exitoso y guardado en cache');
        print('🔐 ============ FIN LOGIN ============\n');
        return data;
        
      } catch (e) {
        print('   ⚠️ Fallo login online: $e');
        print('   🔄 Intentando modo OFFLINE como respaldo...');
        
        // Si falla online, intentar offline
        return await _loginOffline(email, password);
      }
    } else {
      // ✅ MODO OFFLINE
      print('   📱 Modo OFFLINE activado');
      return await _loginOffline(email, password);
    }
  }

  /// Login contra el servidor (modo online)
  static Future<Map<String, dynamic>> _loginOnline(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "contraseña": password,
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Timeout: Servidor no responde');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Credenciales incorrectas (${response.statusCode})');
    }
  }

  /// Login usando SQLite (modo offline)
  static Future<Map<String, dynamic>> _loginOffline(String email, String password) async {
    print('      🗄️ Consultando SQLite...');
    
    try {
      final esValido = await _dbHelper.validarCredencialesOffline(email, password);
      
      if (!esValido) {
        print('      ❌ Credenciales inválidas o no encontradas');
        
        // ✅ Mensaje más claro
        throw Exception(
          'Credenciales incorrectas o no guardadas.\n'
          'Inicia sesión con internet al menos una vez.'
        );
      }
      
      final usuario = await _dbHelper.obtenerUsuarioPorEmail(email);
      
      if (usuario == null) {
        throw Exception('Usuario no encontrado después de validación');
      }
      
      // Convertir datos de SQLite al formato esperado
      final data = {
        'id': usuario['id'],
        'nombre': usuario['nombre'],
        'email': usuario['email'],
        'rol': usuario['rol'],
      };
      
      UsuarioSesion.guardarUsuario(data);
      print('      ✅ Login OFFLINE exitoso desde cache');
      print('🔐 ============ FIN LOGIN ============\n');
      return data;
      
    } catch (e) {
      print('      ❌ ERROR en login offline: $e');
      rethrow;
    }
  }

  /// Verificar si el usuario ya ha iniciado sesión antes
  static Future<bool> tieneCredencialesGuardadas(String email) async {
    final usuario = await _dbHelper.obtenerUsuarioPorEmail(email);
    return usuario != null;
  }

  /// ✅ NUEVO: Debug - Listar usuarios guardados
  static Future<void> listarUsuariosGuardados() async {
    final usuarios = await _dbHelper.listarTodosLosUsuarios();
    print('\n📋 ============ USUARIOS EN BD ============');
    print('   Total: ${usuarios.length}');
    for (var u in usuarios) {
      print('   - ${u['email']} | ${u['nombre']} | Rol: ${u['rol']}');
    }
    print('📋 ============ FIN LISTA ============\n');
  }
}