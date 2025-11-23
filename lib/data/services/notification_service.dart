import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ferti_go/data/models/solicitud_fertilizante_model.dart';
import 'package:ferti_go/data/services/solicitud_service.dart';

class Notificacion {
  final int idSolicitud;
  final String tipoFertilizante;
  final String estadoAnterior;
  final String estadoNuevo;
  final DateTime fecha;
  final bool leida;

  Notificacion({
    required this.idSolicitud,
    required this.tipoFertilizante,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.fecha,
    this.leida = false,
  });

  Map<String, dynamic> toJson() => {
    'idSolicitud': idSolicitud,
    'tipoFertilizante': tipoFertilizante,
    'estadoAnterior': estadoAnterior,
    'estadoNuevo': estadoNuevo,
    'fecha': fecha.toIso8601String(),
    'leida': leida,
  };

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
    idSolicitud: json['idSolicitud'],
    tipoFertilizante: json['tipoFertilizante'],
    estadoAnterior: json['estadoAnterior'],
    estadoNuevo: json['estadoNuevo'],
    fecha: DateTime.parse(json['fecha']),
    leida: json['leida'] ?? false,
  );

  String get mensaje {
    switch (estadoNuevo.toUpperCase()) {
      case 'APROBADA':
        return 'Su solicitud de $tipoFertilizante ha sido APROBADA ✅';
      case 'RECHAZADA':
        return 'Su solicitud de $tipoFertilizante ha sido RECHAZADA ❌';
      case 'EN_PROCESO':
        return 'Su solicitud de $tipoFertilizante está EN PROCESO 🔄';
      default:
        return 'Su solicitud de $tipoFertilizante cambió a $estadoNuevo';
    }
  }
}

class NotificationService {
  static const String _keyEstadosAnteriores = 'estados_solicitudes';
  static const String _keyNotificaciones = 'notificaciones_usuario';
  
  final SolicitudService _solicitudService = SolicitudService();

  // 🔔 Verificar si hay cambios de estado
  Future<List<Notificacion>> verificarCambiosDeEstado(int idUsuario) async {
    try {
      print('🔔 Verificando cambios de estado para usuario #$idUsuario');
      
      // Obtener solicitudes actuales del servidor
      final solicitudesActuales = await _solicitudService.obtenerSolicitudesPorUsuario(idUsuario);
      
      // Obtener estados anteriores guardados
      final estadosAnteriores = await _obtenerEstadosAnteriores(idUsuario);
      
      List<Notificacion> nuevasNotificaciones = [];
      
      // Comparar estados
      for (var solicitud in solicitudesActuales) {
        final estadoAnterior = estadosAnteriores[solicitud.idSolicitud.toString()];
        
        if (estadoAnterior != null && estadoAnterior != solicitud.estado) {
          // ¡Se detectó un cambio de estado!
          print('🚨 Cambio detectado en solicitud #${solicitud.idSolicitud}: $estadoAnterior → ${solicitud.estado}');
          
          final notificacion = Notificacion(
            idSolicitud: solicitud.idSolicitud,
            tipoFertilizante: solicitud.tipoFertilizante,
            estadoAnterior: estadoAnterior,
            estadoNuevo: solicitud.estado,
            fecha: DateTime.now(),
          );
          
          nuevasNotificaciones.add(notificacion);
        }
      }
      
      // Guardar estados actuales
      await _guardarEstadosActuales(idUsuario, solicitudesActuales);
      
      // Guardar nuevas notificaciones
      if (nuevasNotificaciones.isNotEmpty) {
        await _agregarNotificaciones(idUsuario, nuevasNotificaciones);
      }
      
      return nuevasNotificaciones;
      
    } catch (e) {
      print('❌ Error verificando cambios: $e');
      return [];
    }
  }

  // 📝 Guardar estados actuales
  Future<void> _guardarEstadosActuales(int idUsuario, List<SolicitudFertilizanteModel> solicitudes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      Map<String, String> estados = {};
      for (var solicitud in solicitudes) {
        estados[solicitud.idSolicitud.toString()] = solicitud.estado;
      }
      
      final key = '${_keyEstadosAnteriores}_$idUsuario';
      await prefs.setString(key, json.encode(estados));
      
      print('💾 Estados guardados: ${estados.length} solicitudes');
    } catch (e) {
      print('❌ Error guardando estados: $e');
    }
  }

  // 📖 Obtener estados anteriores
  Future<Map<String, String>> _obtenerEstadosAnteriores(int idUsuario) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyEstadosAnteriores}_$idUsuario';
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) return {};
      
      final Map<String, dynamic> decoded = json.decode(jsonString);
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      print('❌ Error obteniendo estados anteriores: $e');
      return {};
    }
  }

  // 💾 Agregar notificaciones
  Future<void> _agregarNotificaciones(int idUsuario, List<Notificacion> nuevas) async {
    try {
      final notificacionesActuales = await obtenerNotificaciones(idUsuario);
      notificacionesActuales.addAll(nuevas);
      
      // Mantener solo las últimas 50 notificaciones
      if (notificacionesActuales.length > 50) {
        notificacionesActuales.removeRange(0, notificacionesActuales.length - 50);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyNotificaciones}_$idUsuario';
      
      final jsonList = notificacionesActuales.map((n) => n.toJson()).toList();
      await prefs.setString(key, json.encode(jsonList));
      
      print('💾 ${nuevas.length} nuevas notificaciones guardadas');
    } catch (e) {
      print('❌ Error guardando notificaciones: $e');
    }
  }

  // 📋 Obtener todas las notificaciones
  Future<List<Notificacion>> obtenerNotificaciones(int idUsuario) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyNotificaciones}_$idUsuario';
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) return [];
      
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((json) => Notificacion.fromJson(json)).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha)); // Más recientes primero
      
    } catch (e) {
      print('❌ Error obteniendo notificaciones: $e');
      return [];
    }
  }

  // 📊 Contar notificaciones no leídas
  Future<int> contarNoLeidas(int idUsuario) async {
    final notificaciones = await obtenerNotificaciones(idUsuario);
    return notificaciones.where((n) => !n.leida).length;
  }

  // ✅ Marcar notificación como leída
  Future<void> marcarComoLeida(int idUsuario, int idSolicitud) async {
    try {
      final notificaciones = await obtenerNotificaciones(idUsuario);
      
      for (var notif in notificaciones) {
        if (notif.idSolicitud == idSolicitud) {
          final index = notificaciones.indexOf(notif);
          notificaciones[index] = Notificacion(
            idSolicitud: notif.idSolicitud,
            tipoFertilizante: notif.tipoFertilizante,
            estadoAnterior: notif.estadoAnterior,
            estadoNuevo: notif.estadoNuevo,
            fecha: notif.fecha,
            leida: true,
          );
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyNotificaciones}_$idUsuario';
      final jsonList = notificaciones.map((n) => n.toJson()).toList();
      await prefs.setString(key, json.encode(jsonList));
      
    } catch (e) {
      print('❌ Error marcando como leída: $e');
    }
  }

  // 🗑️ Marcar todas como leídas
  Future<void> marcarTodasComoLeidas(int idUsuario) async {
    try {
      final notificaciones = await obtenerNotificaciones(idUsuario);
      
      final notificacionesLeidas = notificaciones.map((n) => Notificacion(
        idSolicitud: n.idSolicitud,
        tipoFertilizante: n.tipoFertilizante,
        estadoAnterior: n.estadoAnterior,
        estadoNuevo: n.estadoNuevo,
        fecha: n.fecha,
        leida: true,
      )).toList();
      
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyNotificaciones}_$idUsuario';
      final jsonList = notificacionesLeidas.map((n) => n.toJson()).toList();
      await prefs.setString(key, json.encode(jsonList));
      
    } catch (e) {
      print('❌ Error marcando todas como leídas: $e');
    }
  }

  // 🗑️ Eliminar una notificación específica
  Future<void> eliminarNotificacion(int idUsuario, int idSolicitud, DateTime fecha) async {
    try {
      final notificaciones = await obtenerNotificaciones(idUsuario);
      
      // Filtrar la notificación a eliminar (comparando por ID y fecha para evitar duplicados)
      final notificacionesFiltradas = notificaciones.where((n) => 
        !(n.idSolicitud == idSolicitud && n.fecha == fecha)
      ).toList();
      
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyNotificaciones}_$idUsuario';
      final jsonList = notificacionesFiltradas.map((n) => n.toJson()).toList();
      await prefs.setString(key, json.encode(jsonList));
      
      print('🗑️ Notificación eliminada correctamente');
    } catch (e) {
      print('❌ Error eliminando notificación: $e');
    }
  }

  // 🗑️ Eliminar TODAS las notificaciones
  Future<void> eliminarTodasLasNotificaciones(int idUsuario) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_keyNotificaciones}_$idUsuario';
      await prefs.remove(key);
      
      print('🗑️ Todas las notificaciones eliminadas');
    } catch (e) {
      print('❌ Error eliminando todas las notificaciones: $e');
    }
  }

  // 🔄 Inicializar estados (primera vez)
  Future<void> inicializarEstados(int idUsuario) async {
    try {
      final solicitudes = await _solicitudService.obtenerSolicitudesPorUsuario(idUsuario);
      await _guardarEstadosActuales(idUsuario, solicitudes);
      print('✅ Estados inicializados para usuario #$idUsuario');
    } catch (e) {
      print('❌ Error inicializando estados: $e');
    }
  }
}