import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
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
      final socket = await Socket.connect(
        '192.168.1.25',
        8080,
        timeout: const Duration(seconds: 2),
      );
      
      socket.destroy();
      print('Servidor disponible');
      return true;
      
    } on SocketException catch (e) {
      print('Servidor inaccesible: ${e.message}');
      return false;
    } on TimeoutException catch (_) {
      print('Timeout conectando al servidor');
      return false;
    } catch (e) {
      print('Error: $e');
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