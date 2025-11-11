import 'package:ferti_go/presentation/pages/ajustes_page.dart';
import 'package:ferti_go/presentation/pages/solicitud_fertilizante.dart';
import 'package:ferti_go/presentation/pages/mis_pedidos.dart';
import 'package:ferti_go/presentation/widgets/boton_menu.dart';
import 'package:ferti_go/presentation/widgets/fondo_agricultor.dart';
import 'package:flutter/material.dart';

class Inicio extends StatelessWidget {
  // 🔥 Recibe el ID del usuario logueado
  final int idUsuario;
  
  const Inicio({
    super.key,
    required this.idUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FondoAgricultor(),
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
                          builder: (context) =>  MisPedidosPage(
                            idUsuario: idUsuario, 
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
                      Navigator.push(context, 
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