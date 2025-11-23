import 'package:flutter/material.dart';

class FondoAgricultor extends StatelessWidget {
  const FondoAgricultor({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/agricultor2.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(-0.3, 0),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.4)),
        Positioned(
          top: 55,
          left: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/Logo.png',
              width: 100,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
