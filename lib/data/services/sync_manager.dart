import 'dart:async';
import 'package:ferti_go/data/services/connectivity_service.dart';
import 'package:ferti_go/data/services/solicitud_fertilizante_offline_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  final SolicitudFertilizanteOfflineService _service = 
      SolicitudFertilizanteOfflineService();
  
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool _lastConnectionState = false;

  void startAutoSync() {
    print('SyncManager iniciado');
    
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (isConnected) {
        _onConnectivityChanged(isConnected);
      },
      onError: (error) {
        print('Error en stream de conectividad: $error');
      },
    );

    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      const Duration(seconds: 30), 
      (_) => _syncIfNeeded(),
    );

    Future.delayed(const Duration(seconds: 2), () {
      print('Sincronización inicial programada');
      _syncIfNeeded();
    });
  }

  void _onConnectivityChanged(bool isConnected) {
    print('Cambio de conexión detectado: ${isConnected ? "ONLINE" : "OFFLINE"}');
    
    if (isConnected && !_lastConnectionState) {
      print('Servidor recuperado, sincronizando...');
      
      Future.delayed(const Duration(seconds: 2), () {
        syncNow();
      });
    }
    
    _lastConnectionState = isConnected;
  }

  Future<void> _syncIfNeeded() async {
    if (_isSyncing) {
      return;
    }

    try {
      final pendientes = await _service.contarSolicitudesPendientes();
      
      if (pendientes == 0) {
        return;
      }

      final hayConexion = await _connectivity.checkServerConnection();
      
      if (!hayConexion) {
        return;
      }

      await syncNow();
      
    } catch (e) {
      print('Error en verificación de sincronización: $e');
    }
  }

  Future<Map<String, dynamic>> syncNow() async {
    if (_isSyncing) {
      return {
        'exito': false,
        'mensaje': 'Sincronización ya en curso',
      };
    }

    _isSyncing = true;

    try {
      final hayConexion = await _connectivity.checkServerConnectionWithRetry(
        maxRetries: 2,
      );
      
      if (!hayConexion) {
        return {
          'exito': false,
          'mensaje': 'Sin conexión al servidor',
        };
      }

      final resultado = await _service.sincronizarSolicitudesPendientes();
      
      return resultado;
      
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error al sincronizar: $e',
      };
    } finally {
      _isSyncing = false;
    }
  }

  void stopAutoSync() {
    print('SyncManager detenido');
    
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    
    _isSyncing = false;
    _lastConnectionState = false;
  }

  bool get isSyncing => _isSyncing;
  bool get isConnected => _lastConnectionState;
  
  Future<bool> checkServerStatus() async {
    return await _connectivity.checkServerConnection();
  }
}