import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ferti_go.db');

    print('📂 Ruta de base de datos: $path');

    return await openDatabase(
      path,
      version: 2, // ✅ Incrementar versión para forzar actualización
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🔨 Creando base de datos v$version...');
    
    // ✅ Tabla de usuarios (credenciales offline)
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        contrasena TEXT NOT NULL,
        rol TEXT NOT NULL,
        fechaGuardado TEXT NOT NULL
      )
    ''');

    // ✅ Tabla de solicitudes offline (pendientes de sincronizar)
    await db.execute('''
      CREATE TABLE solicitudes_pendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idUsuario INTEGER NOT NULL,
        tipoFertilizante TEXT NOT NULL,
        cantidad REAL NOT NULL,
        fechaRequerida TEXT NOT NULL,
        prioridad TEXT NOT NULL,
        motivo TEXT,
        notas TEXT,
        finca TEXT,
        ubicacion TEXT,
        estado TEXT DEFAULT 'PENDIENTE',
        fechaCreacion TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        FOREIGN KEY (idUsuario) REFERENCES usuarios(id)
      )
    ''');

    // ✅ Tabla de solicitudes sincronizadas (cache)
    await db.execute('''
      CREATE TABLE solicitudes_cache (
        idSolicitud INTEGER PRIMARY KEY,
        idUsuario INTEGER NOT NULL,
        tipoFertilizante TEXT NOT NULL,
        cantidad REAL NOT NULL,
        fechaRequerida TEXT NOT NULL,
        prioridad TEXT NOT NULL,
        motivo TEXT,
        notas TEXT,
        finca TEXT,
        ubicacion TEXT,
        estado TEXT,
        fechaActualizacion TEXT NOT NULL
      )
    ''');

    // ✅ Tabla de tipos de fertilizantes (cache)
    await db.execute('''
      CREATE TABLE fertilizantes_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT UNIQUE NOT NULL,
        fechaActualizacion TEXT NOT NULL
      )
    ''');

    print('✅ Base de datos creada exitosamente');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de v$oldVersion a v$newVersion');
    // Aquí puedes agregar migraciones si es necesario
  }

  // ==================== MÉTODOS DE USUARIOS ====================
  
  Future<void> guardarUsuario(Map<String, dynamic> usuario) async {
    try {
      final db = await database;
      
      final datos = {
        'id': usuario['id'],
        'nombre': usuario['nombre'],
        'email': usuario['email'],
        'contrasena': usuario['contraseña'] ?? usuario['contrasena'], // ✅ Ambas formas
        'rol': usuario['rol'],
        'fechaGuardado': DateTime.now().toIso8601String(),
      };

      print('💾 Intentando guardar usuario: ${datos['email']}');
      
      await db.insert(
        'usuarios',
        datos,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ Usuario guardado en SQLite exitosamente');
      
      // ✅ Verificar que se guardó correctamente
      final verificacion = await obtenerUsuarioPorEmail(datos['email']);
      if (verificacion != null) {
        print('✅ Verificación exitosa: Usuario encontrado en BD');
      } else {
        print('⚠️ WARNING: Usuario no encontrado después de guardar');
      }
      
    } catch (e) {
      print('❌ ERROR guardando usuario: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuarioPorEmail(String email) async {
    try {
      final db = await database;
      
      print('🔍 Buscando usuario: $email');
      
      final result = await db.query(
        'usuarios',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (result.isNotEmpty) {
        print('✅ Usuario encontrado: ${result.first['nombre']}');
        return result.first;
      } else {
        print('❌ Usuario NO encontrado en BD');
        
        // ✅ Debug: Listar todos los usuarios
        final todosLosUsuarios = await db.query('usuarios');
        print('📋 Total usuarios en BD: ${todosLosUsuarios.length}');
        for (var u in todosLosUsuarios) {
          print('   - ${u['email']} (ID: ${u['id']})');
        }
        
        return null;
      }
    } catch (e) {
      print('❌ ERROR obteniendo usuario: $e');
      return null;
    }
  }

  Future<bool> validarCredencialesOffline(String email, String password) async {
    try {
      print('🔐 Validando credenciales offline...');
      print('   Email: $email');
      
      final usuario = await obtenerUsuarioPorEmail(email);
      
      if (usuario == null) {
        print('❌ Usuario no existe en BD local');
        return false;
      }
      
      final passwordMatch = usuario['contrasena'] == password;
      final rolMatch = usuario['rol'] == 'CAPATAZ';
      
      print('   Password match: $passwordMatch');
      print('   Rol match: $rolMatch (Rol: ${usuario['rol']})');
      
      return passwordMatch && rolMatch;
      
    } catch (e) {
      print('❌ ERROR validando credenciales: $e');
      return false;
    }
  }

  // ==================== SOLICITUDES PENDIENTES ====================
  
  Future<int> guardarSolicitudPendiente(Map<String, dynamic> solicitud) async {
    final db = await database;
    
    final id = await db.insert(
      'solicitudes_pendientes',
      {
        ...solicitud,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'sincronizado': 0,
      },
    );
    
    print('✅ Solicitud guardada offline (ID local: $id)');
    return id;
  }

  Future<List<Map<String, dynamic>>> obtenerSolicitudesPendientes(int idUsuario) async {
    final db = await database;
    
    return await db.query(
      'solicitudes_pendientes',
      where: 'idUsuario = ? AND sincronizado = 0',
      whereArgs: [idUsuario],
      orderBy: 'fechaCreacion DESC',
    );
  }

  Future<void> marcarComoSincronizado(int idLocal) async {
    final db = await database;
    
    // ✅ ELIMINAR en lugar de marcar (evita duplicados)
    await db.delete(
      'solicitudes_pendientes',
      where: 'id = ?',
      whereArgs: [idLocal],
    );
    
    print('✅ Solicitud #$idLocal eliminada de pendientes');
  }

  // ==================== CACHE DE SOLICITUDES ====================
  
  Future<void> guardarSolicitudesCache(List<Map<String, dynamic>> solicitudes) async {
    final db = await database;
    
    // Limpiar cache anterior del usuario
    if (solicitudes.isNotEmpty) {
      await db.delete(
        'solicitudes_cache',
        where: 'idUsuario = ?',
        whereArgs: [solicitudes.first['idUsuario']],
      );
    }
    
    // Guardar nuevas
    for (var solicitud in solicitudes) {
      await db.insert(
        'solicitudes_cache',
        {
          ...solicitud,
          'fechaActualizacion': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    print('✅ ${solicitudes.length} solicitudes guardadas en cache');
  }

  Future<List<Map<String, dynamic>>> obtenerSolicitudesCache(int idUsuario) async {
    final db = await database;
    
    return await db.query(
      'solicitudes_cache',
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fechaActualizacion DESC',
    );
  }

  // ==================== CACHE DE FERTILIZANTES ====================
  
  Future<void> guardarFertilizantesCache(List<String> fertilizantes) async {
    final db = await database;
    
    await db.delete('fertilizantes_cache'); // Limpiar cache
    
    for (var fertilizante in fertilizantes) {
      await db.insert(
        'fertilizantes_cache',
        {
          'nombre': fertilizante,
          'fechaActualizacion': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    print('${fertilizantes.length} fertilizantes guardados en cache');
  }

  Future<List<String>> obtenerFertilizantesCache() async {
    final db = await database;
    
    final result = await db.query('fertilizantes_cache');
    return result.map((row) => row['nombre'] as String).toList();
  }

  // ==================== DEBUG Y MANTENIMIENTO ====================
  
  /// NUEVO: Listar todos los usuarios (para debug)
  Future<List<Map<String, dynamic>>> listarTodosLosUsuarios() async {
    final db = await database;
    return await db.query('usuarios');
  }

  /// NUEVO: Resetear base de datos (solo para desarrollo)
  Future<void> resetearBaseDatos() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ferti_go.db');
    
    await deleteDatabase(path);
    print('Base de datos eliminada');
    
    _database = null;
    await database; // Recrear
    print('✅ Base de datos recreada');
  }

  // ==================== LIMPIEZA ====================
  
  Future<void> limpiarCache() async {
    final db = await database;
    
    await db.delete('solicitudes_cache');
    await db.delete('fertilizantes_cache');
    
    print('Cache limpiado');
  }

  Future<void> cerrarDB() async {
    final db = await database;
    await db.close();
  }
}