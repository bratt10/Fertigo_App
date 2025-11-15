import 'package:ferti_go/data/services/novedades_service.dart';
import 'package:flutter/material.dart';

class NovedadesScreen extends StatefulWidget {
  const NovedadesScreen({super.key});

  @override
  State<NovedadesScreen> createState() => _NovedadesScreenState();
}

class _NovedadesScreenState extends State<NovedadesScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController fincaController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController novedadController = TextEditingController();

  bool enviando = false;

  Future<void> enviarNovedad() async {
    if (nombreController.text.isEmpty ||
        fincaController.text.isEmpty ||
        correoController.text.isEmpty ||
        novedadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => enviando = true);

    try {
      final enviado = await NovedadesService.enviarNovedad(
        nombre: nombreController.text,
        finca: fincaController.text,
        correo: correoController.text,
        novedad: novedadController.text,
      );

      if (enviado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Novedad enviada correctamente."),
            backgroundColor: Colors.green,
          ),
        );

        nombreController.clear();
        fincaController.clear();
        correoController.clear();
        novedadController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de conexión: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ganadero.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/LogoSinFondo.png', width: 140),
                    const SizedBox(height: 15),
                    const Text(
                      '¿Tienes problemas para ingresar?',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        hintText: 'Ingrese su nombre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fincaController,
                      decoration: InputDecoration(
                        hintText: 'Nombre de finca',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Correo electrónico',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: novedadController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Escriba su novedad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: enviando ? null : enviarNovedad,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: enviando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Enviar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
