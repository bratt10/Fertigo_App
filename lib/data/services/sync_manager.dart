import 'dart:async';
import 'package:ferti_go/data/services/connectivity_service.dart';
import 'package:ferti_go/data/services/solicitud_fertilizante_offline_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  final SolicitudFertilizanteOfflineService _service = SolicitudFertilizanteOfflineService();
  
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool _lastConnectionState = false;

  /// ✅ Iniciar monitoreo de conexión y sincronización automática
  void startAutoSync() {
    print('🔄 Iniciando sincronización automática...');
    
    // Escuchar cambios de conexión
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((isConnected) {
      _onConnectivityChanged(isConnected);
    });

    // Timer periódico cada 30 segundos (cuando hay conexión)
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncIfNeeded();
    });

    // Intentar sincronización inicial
    Future.delayed(const Duration(seconds: 2), () {
      _syncIfNeeded();
    });
  }

  /// ✅ Detectar cuando se recupera la conexión
  void _onConnectivityChanged(bool isConnected) {
    print('📡 Cambio de conexión: ${isConnected ? "ONLINE" : "OFFLINE"}');
    
    // Si acabamos de conectarnos (transición de offline a online)
    if (isConnected && !_lastConnectionState) {
      print('🎉 ¡Conexión recuperada! Sincronizando...');
      Future.delayed(const Duration(seconds: 2), () {
        syncNow();
      });
    }
    
    _lastConnectionState = isConnected;
  }

  /// ✅ Sincronizar solo si hay conexión y hay pendientes
  Future<void> _syncIfNeeded() async {
    if (_isSyncing) {
      print('⏳ Ya hay una sincronización en curso');
      return;
    }

    try {
      // Verificar si hay pendientes
      final pendientes = await _service.contarSolicitudesPendientes();
      
      if (pendientes == 0) {
        return; // No hay nada que sincronizar
      }

      // Verificar conexión rápida
      final hayConexion = await _connectivity.checkConnectionFast();
      
      if (!hayConexion) {
        print('📱 Sin conexión, esperando...');
        return;
      }

      // Sincronizar
      await syncNow();
      
    } catch (e) {
      print('⚠️ Error en sincronización automática: $e');
    }
  }

  /// ✅ Forzar sincronización ahora
  Future<Map<String, dynamic>> syncNow() async {
    if (_isSyncing) {
      return {
        'exito': false,
        'mensaje': 'Sincronización ya en curso',
      };
    }

    _isSyncing = true;
    print('\n🚀 ============ SINCRONIZACIÓN FORZADA ============');

    try {
      final resultado = await _service.sincronizarSolicitudesPendientes();
      print('📊 Resultado sincronización: ${resultado['mensaje']}');
      print('🚀 ============ FIN SINCRONIZACIÓN ============\n');
      return resultado;
      
    } catch (e) {
      print('❌ Error en sincronización: $e');
      return {
        'exito': false,
        'mensaje': 'Error: $e',
      };
    } finally {
      _isSyncing = false;
    }
  }

  /// ✅ Detener sincronización automática (al cerrar app)
  void stopAutoSync() {
    print('⏹️ Deteniendo sincronización automática');
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }

  /// ✅ Obtener estado de sincronización
  bool get isSyncing => _isSyncing;
  
  /// ✅ Obtener estado de conexión
  bool get isConnected => _lastConnectionState;
}