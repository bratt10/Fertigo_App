import 'package:ferti_go/data/services/conexion_login_offline.dart';
import 'package:ferti_go/data/services/connectivity_service.dart';
import 'package:ferti_go/data/models/usuario_sesion.dart';
import 'package:ferti_go/presentation/pages/novedades.dart';
import 'package:flutter/material.dart';
import 'package:ferti_go/presentation/pages/inicio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  bool cargando = false;
  bool? hayConexion; // null = verificando, true = online, false = offline

  @override
  void initState() {
    super.initState();
    _verificarConexion();
    
    // Escuchar cambios de conectividad en tiempo real
    _connectivityService.onConnectivityChanged.listen((conectado) {
      if (mounted) {
        setState(() {
          hayConexion = conectado;
        });
      }
    });
  }

  Future<void> _verificarConexion() async {
    final conectado = await _connectivityService.checkConnection();
    if (mounted) {
      setState(() {
        hayConexion = conectado;
      });
    }
  }

  Future<void> iniciarSesion() async {
    // Validar campos vacíos
    if (correoController.text.isEmpty || contrasenaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      // Intentar login (automáticamente online u offline según conexión)
      final data = await ConexionLoginOffline.login(
        correoController.text.trim(),
        contrasenaController.text,
      );

      // Verificar rol
      if (data['rol'] == 'CAPATAZ') {
        final modoLogin = hayConexion == true ? 'online' : 'offline';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  modoLogin == 'online' ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Bienvenid@ ${data['nombre'] ?? 'Usuario'}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        modoLogin == 'online' 
                          ? 'Modo: Online ✓' 
                          : 'Modo: Offline (datos locales)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navegar al inicio
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Inicio(idUsuario: UsuarioSesion.id!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Acceso denegado. Solo los capataces pueden ingresar."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Error al iniciar sesión",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      e.toString().replaceAll('Exception: ', ''),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ganadero.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment(0.3, 0),
              ),
            ),
          ),
          // Sombra encima del fondo
          Container(color: Colors.black.withOpacity(0.2)),
          
          // 🆕 Indicador de conectividad en la parte superior
          if (hayConexion != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (hayConexion! ? Colors.green : Colors.orange)
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hayConexion! ? Icons.cloud_done : Icons.cloud_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hayConexion! ? 'Conectado' : 'Modo Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Contenido centrado (TU DISEÑO ORIGINAL)
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/LogoSinFondo.png', width: 200),
                  const SizedBox(height: 20),
                  TextField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined),
                      labelText: 'CORREO',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: contrasenaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelText: 'CONTRASEÑA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: cargando ? null : iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'INICIAR JORNADA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No puedes ingresar?  "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NovedadesScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Aquí",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }
}