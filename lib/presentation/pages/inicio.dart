import 'package:ferti_go/data/services/notification_service.dart';
import 'package:ferti_go/presentation/pages/ajustes_page.dart';
import 'package:ferti_go/presentation/pages/solicitud_fertilizante.dart';
import 'package:ferti_go/presentation/pages/mis_pedidos.dart';
import 'package:ferti_go/presentation/widgets/boton_menu.dart';
import 'package:ferti_go/presentation/widgets/fondo_agricultor.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Inicio extends StatefulWidget {
  final int idUsuario;
  
  const Inicio({
    super.key,
    required this.idUsuario,
  });

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final NotificationService _notificationService = NotificationService();
  int _cantidadNoLeidas = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _inicializarNotificaciones();
    _iniciarVerificacionPeriodica();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _inicializarNotificaciones() async {
    // Verificar cambios al abrir la app
    await _notificationService.verificarCambiosDeEstado(widget.idUsuario);
    await _actualizarContador();
  }

  void _iniciarVerificacionPeriodica() {
    // Verificar cada 30 segundos si hay cambios
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _notificationService.verificarCambiosDeEstado(widget.idUsuario);
      await _actualizarContador();
    });
  }

  Future<void> _actualizarContador() async {
    final cantidad = await _notificationService.contarNoLeidas(widget.idUsuario);
    if (mounted) {
      setState(() {
        _cantidadNoLeidas = cantidad;
      });
    }
  }

  void _mostrarNotificaciones() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PanelNotificaciones(
        idUsuario: widget.idUsuario,
        onNotificacionLeida: _actualizarContador,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FondoAgricultor(),
          
          // Botón de notificaciones
          Positioned(
            top: 50,
            right: 20,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications, size: 28),
                    color: Colors.green[700],
                    onPressed: _mostrarNotificaciones,
                  ),
                ),
                
                // Badge de notificaciones no leídas
                if (_cantidadNoLeidas > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        _cantidadNoLeidas > 9 ? '9+' : _cantidadNoLeidas.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 100),
                  const Text(
                    '¡Hola Bienvenido!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 90),
                  BotonMenu(
                    icon: Icons.local_florist,
                    text: 'Hacer pedido de\nFertilizantes',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SolicitudFertilizantePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  BotonMenu(
                    icon: Icons.receipt_long,
                    text: 'Mis Pedidos',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MisPedidosPage(
                            idUsuario: widget.idUsuario, 
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  BotonMenu(
                    icon: Icons.settings,
                    text: 'Ajustes',
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const AjustesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PANEL DE NOTIFICACIONES (Bottom Sheet)
// ============================================================
class _PanelNotificaciones extends StatefulWidget {
  final int idUsuario;
  final VoidCallback onNotificacionLeida;

  const _PanelNotificaciones({
    required this.idUsuario,
    required this.onNotificacionLeida,
  });

  @override
  State<_PanelNotificaciones> createState() => _PanelNotificacionesState();
}

class _PanelNotificacionesState extends State<_PanelNotificaciones> {
  final NotificationService _notificationService = NotificationService();
  List<Notificacion> _notificaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _cargando = true);
    
    final notificaciones = await _notificationService.obtenerNotificaciones(widget.idUsuario);
    
    if (mounted) {
      setState(() {
        _notificaciones = notificaciones;
        _cargando = false;
      });
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    await _notificationService.marcarTodasComoLeidas(widget.idUsuario);
    widget.onNotificacionLeida();
    await _cargarNotificaciones();
  }

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'APROBADA':
        return Colors.green;
      case 'RECHAZADA':
        return Colors.red;
      case 'EN_PROCESO':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'APROBADA':
        return Icons.check_circle;
      case 'RECHAZADA':
        return Icons.cancel;
      case 'EN_PROCESO':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Justo ahora';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_notificaciones.any((n) => !n.leida))
                  TextButton(
                    onPressed: _marcarTodasComoLeidas,
                    child: const Text(
                      'Marcar todas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Lista de notificaciones
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _notificaciones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay notificaciones',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notificaciones.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notif = _notificaciones[index];
                          return _buildNotificacionItem(notif);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionItem(Notificacion notif) {
    final color = _getColorEstado(notif.estadoNuevo);
    final icono = _getIconoEstado(notif.estadoNuevo);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notif.leida ? Colors.white : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.leida ? Colors.grey[300]! : Colors.green[200]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(
          notif.mensaje,
          style: TextStyle(
            fontSize: 15,
            fontWeight: notif.leida ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatearFecha(notif.fecha),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '#${notif.idSolicitud}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notif.leida)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[400],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                // Mostrar confirmación
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Eliminar notificación?'),
                    content: const Text(
                      '¿Deseas eliminar esta notificación?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  await _notificationService.eliminarNotificacion(
                    widget.idUsuario,
                    notif.idSolicitud,
                    notif.fecha,
                  );
                  widget.onNotificacionLeida();
                  await _cargarNotificaciones();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🗑️ Notificación eliminada'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        onTap: () async {
          if (!notif.leida) {
            await _notificationService.marcarComoLeida(
              widget.idUsuario,
              notif.idSolicitud,
            );
            widget.onNotificacionLeida();
            await _cargarNotificaciones();
          }
          
          // Opcional: Navegar a la página de detalles
          // Navigator.pop(context);
          // Navigator.push(context, MaterialPageRoute(...));
        },
      ),
    );
  }
}