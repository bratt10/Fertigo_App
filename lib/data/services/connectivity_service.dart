import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.asyncMap((_) => checkConnection());

  /// Verifica conexión directa al servidor backend
  Future<bool> checkConnection() async {
    return await checkServerConnection();
  }

  /// Verifica si el servidor está accesible
  Future<bool> checkServerConnection() async {
    try {
      // En lugar de Socket.connect, hacemos una petición HTTP ligera
      final response = await http.head(
        Uri.parse('https://fertigo-production-0cf0.up.railway.app/fertilizante'),
      ).timeout(const Duration(seconds: 5));
      
      // Si el servidor responde con cualquier código < 500, está disponible
      final isReachable = response.statusCode < 500;
      print(isReachable ? 'Servidor disponible' : 'Servidor caído');
      return isReachable;
      
    } on TimeoutException catch (_) {
      print('Timeout conectando al servidor');
      return false;
    } catch (e) {
      print('Error conectando: $e');
      return false;
    }
  }

  /// Verifica si hay WiFi o datos móviles activados
  Future<bool> checkConnectionFast() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile ||
             connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      return false;
    }
  }
  
  /// Reintenta conexión al servidor (útil para redes inestables)
  Future<bool> checkServerConnectionWithRetry({int maxRetries = 2}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final connected = await checkServerConnection();
      
      if (connected) {
        return true;
      }
      
      if (attempt < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    
    print('Servidor inaccesible después de $maxRetries intentos');
    return false;
  }
}