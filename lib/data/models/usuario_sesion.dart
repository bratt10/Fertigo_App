class UsuarioSesion {
  static int? id;
  static String? nombre;
  static String? rol;
  static String? correo;

  // Método para guardar los datos del usuario
  static void guardarUsuario(Map<String, dynamic> data) {
    id = data['id'];
    nombre = data['nombre'];
    rol = data['rol'];
    correo = data['email'] ?? data['correo'];
    
    print('✅ Usuario guardado en sesión:');
    print('   ID: $id');
    print('   Nombre: $nombre');
    print('   Rol: $rol');
    print('   Correo: $correo');
  }

  // Método para limpiar la sesión al cerrar sesión
  static void cerrarSesion() {
    id = null;
    nombre = null;
    rol = null;
    correo = null;
    print('🚪 Sesión cerrada');
  }

  // Verificar si hay sesión activa
  static bool get tienesSesionActiva => id != null;
}