import 'package:flutter/material.dart';
import 'package:ferti_go/data/models/solicitud_fertilizante.dart';
import 'package:ferti_go/data/services/solicitud_fertilizante_offline_service.dart';

class SolicitudFertilizantePage extends StatefulWidget {
  const SolicitudFertilizantePage({super.key});

  @override
  State<SolicitudFertilizantePage> createState() =>
      _SolicitudFertilizantePageState();
}

class _SolicitudFertilizantePageState extends State<SolicitudFertilizantePage> {
  final _formKey = GlobalKey<FormState>();
  final _service = SolicitudFertilizanteOfflineService();

  // Controladores
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  String? _tipoSeleccionado;
  String _prioridad = 'Media';
  bool _cargando = true;
  bool _error = false;
  int _solicitudesPendientes = 0; // 🆕 Contador de solicitudes pendientes
  List<String> _tiposFertilizantes = [];

  final List<String> _nivelesPrioridad = ['Alta', 'Media', 'Baja'];

  @override
  void initState() {
    super.initState();
    _cargarFertilizantes();
    _cargarContadorPendientes(); // 🆕 Cargar contador
  }

  Future<void> _cargarFertilizantes() async {
    try {
      final tipos = await _service.obtenerTiposFertilizantes();
      if (!mounted) return;

      setState(() {
        _tiposFertilizantes = tipos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _cargando = false;
      });
      
      // 🆕 Mostrar error más descriptivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // 🆕 Cargar contador de solicitudes pendientes
  Future<void> _cargarContadorPendientes() async {
    final count = await _service.contarSolicitudesPendientes();
    if (mounted) {
      setState(() {
        _solicitudesPendientes = count;
      });
    }
  }

  // 🆕 Sincronizar solicitudes pendientes
  Future<void> _sincronizarPendientes() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Sincronizando solicitudes...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      final resultado = await _service.sincronizarSolicitudesPendientes();
      
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                resultado['exito'] ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(resultado['mensaje'])),
            ],
          ),
          backgroundColor: resultado['exito'] ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      
      _cargarContadorPendientes();
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en sincronización: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    final solicitud = SolicitudFertilizante(
      tipoFertilizante: _tipoSeleccionado!,
      cantidad: double.tryParse(_cantidadController.text) ?? 0,
      fechaRequerida: _fechaController.text,
      motivo: _motivoController.text,
      notas: _notasController.text,
      prioridad: _prioridad,
    );

    // 🆕 Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // 🆕 Usar servicio offline que maneja online/offline automáticamente
      final resultado = await _service.enviarSolicitud(solicitud);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga
      
      final esOffline = resultado['modo'] == 'offline';
      
      // 🆕 Mensaje mejorado según el modo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                esOffline ? Icons.save_alt : Icons.cloud_done,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      esOffline 
                        ? '✅ Solicitud guardada localmente'
                        : '✅ Solicitud enviada correctamente',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (esOffline)
                      const Text(
                        'Se sincronizará cuando haya conexión',
                        style: TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: esOffline ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 4),
          action: esOffline
              ? SnackBarAction(
                  label: 'Sincronizar',
                  textColor: Colors.white,
                  onPressed: _sincronizarPendientes,
                )
              : null,
        ),
      );

      // Limpiar formulario
      _cantidadController.clear();
      _fechaController.clear();
      _motivoController.clear();
      _notasController.clear();

      setState(() {
        _tipoSeleccionado = null;
        _prioridad = 'Media';
      });
      
      // 🆕 Actualizar contador
      _cargarContadorPendientes();
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _fechaController.dispose();
    _motivoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Solicitud de Fertilizante',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        elevation: 4,
        // 🆕 Botón de sincronización solo si hay pendientes
        actions: [
          if (_solicitudesPendientes > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  onPressed: _sincronizarPendientes,
                  tooltip: 'Sincronizar pendientes',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_solicitudesPendientes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          // Fondo con imagen (TU DISEÑO ORIGINAL)
          Positioned.fill(
            child: Image.asset(
              'assets/images/agricultor2.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(-0.3, 0),
            ),
          ),
          // Overlay oscuro
          Container(color: Colors.black.withOpacity(0.5)),

          // Contenido del formulario
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _cargando
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 200),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : _error
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 200),
                          child: Column(
                            children: [
                              const Text(
                                '❌ Error al cargar fertilizantes',
                                style: TextStyle(color: Colors.red, fontSize: 18),
                              ),
                              const SizedBox(height: 16),
                              // 🆕 Botón de reintentar
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _cargando = true;
                                    _error = false;
                                  });
                                  _cargarFertilizantes();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                              'Completa los datos para solicitar tu fertilizante',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // Dropdown de tipo de fertilizante
                            _buildDropdown(),
                            const SizedBox(height: 20),

                            // Campo de cantidad
                            _buildTextField(
                              controller: _cantidadController,
                              label: 'Cantidad (kg)',
                              icon: Icons.scale,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),

                            // Campo de fecha
                            _buildTextField(
                              controller: _fechaController,
                              label: 'Fecha Requerida',
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: _seleccionarFecha,
                            ),
                            const SizedBox(height: 20),

                            // Campo de motivo
                            _buildTextField(
                              controller: _motivoController,
                              label: 'Motivo de la Solicitud',
                              icon: Icons.help_outline,
                            ),
                            const SizedBox(height: 20),

                            // Campo de notas
                            _buildTextField(
                              controller: _notasController,
                              label: 'Notas u Observaciones',
                              icon: Icons.note_alt_outlined,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 20),

                            // Dropdown de prioridad
                            DropdownButtonFormField<String>(
                              value: _prioridad,
                              dropdownColor: Colors.green[900],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Prioridad',
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                prefixIcon: const Icon(Icons.flag_circle,
                                    color: Colors.white),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _nivelesPrioridad.map((nivel) {
                                return DropdownMenuItem(
                                  value: nivel,
                                  child: Text(nivel,
                                      style: const TextStyle(
                                          color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (valor) {
                                setState(() {
                                  _prioridad = valor!;
                                });
                              },
                            ),
                            const SizedBox(height: 40),

                            // Botón de enviar (TU DISEÑO ORIGINAL)
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _enviarSolicitud,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 6,
                                ),
                                child: const Text(
                                  'Enviar Solicitud',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Widget para campos de texto reutilizable (TU DISEÑO ORIGINAL)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
    );
  }

  // Widget para dropdown de fertilizantes (TU DISEÑO ORIGINAL)
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _tipoSeleccionado,
      dropdownColor: Colors.green[900],
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Tipo de Fertilizante',
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        prefixIcon: const Icon(Icons.agriculture, color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _tiposFertilizantes.map((tipo) {
        return DropdownMenuItem(
          value: tipo,
          child: Text(tipo, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _tipoSeleccionado = value;
        });
      },
      validator: (value) =>
          value == null ? 'Selecciona un tipo de fertilizante' : null,
    );
  }

  // Método para seleccionar fecha (TU DISEÑO ORIGINAL)
  Future<void> _seleccionarFecha() async {
    DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green[600]!,
              onPrimary: Colors.white,
              surface: Colors.green[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaController.text =
            '${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}';
      });
    }
  }
}