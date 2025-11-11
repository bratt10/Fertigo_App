import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  
  // ✅ Stream mejorado para detectar cambios
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.asyncMap((_) => checkConnection());

  /// Verifica si hay conexión a internet real (no solo WiFi/datos activados)
  Future<bool> checkConnection() async {
    try {
      // 1. Verificar conectividad básica
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // ✅ Compatible con versiones antiguas de connectivity_plus
      if (connectivityResult == ConnectivityResult.none) {
        print('❌ Sin conexión: Modo avión o sin red');
        return false;
      }

      // 2. Hacer ping real para confirmar internet
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
          
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Conexión a internet confirmada');
        return true;
      }
      
      return false;
    } on SocketException catch (_) {
      print('❌ Sin internet: Ping falló');
      return false;
    } catch (e) {
      print('❌ Error verificando conexión: $e');
      return false;
    }
  }

  /// Verifica si puede conectarse al servidor de Ferti-Go
  Future<bool> checkServerConnection() async {
    try {
      // ✅ Usar la IP correcta de tus logs
      final socket = await Socket.connect(
        '192.168.137.34', // Esta es la IP que funciona según tus logs
        8080,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      print('✅ Servidor Ferti-Go alcanzable');
      return true;
    } catch (e) {
      print('❌ Servidor Ferti-Go inaccesible: $e');
      return false;
    }
  }

  /// ✅ NUEVO: Verificar estado actual sin timeout largo
  Future<bool> checkConnectionFast() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // ✅ Compatible con versiones antiguas
      return connectivityResult == ConnectivityResult.mobile ||
             connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      return false;
    }
  }
}