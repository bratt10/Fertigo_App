
class ApiConfig {
  // Usa la IP que esté funcionando en tu red
  static const String baseUrl = "http://192.168.1.25:8080";
  
  // Endpoints
  static const String login = "$baseUrl/Login";
  static const String fertilizantes = "$baseUrl/fertilizante";
  static const String solicitudes = "$baseUrl/solicitudFertilizante";
  
  // Para debugging
  static void printConfig() {
    print('🌐 API Base URL: $baseUrl');
    print('🔐 Login: $login');
    print('🌱 Fertilizantes: $fertilizantes');
    print('📦 Solicitudes: $solicitudes');
  }
}