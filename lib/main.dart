import 'package:flutter/material.dart';
import 'package:ferti_go/presentation/pages/login.dart';
import 'package:ferti_go/data/services/sync_manager.dart'; // Importar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Iniciar sincronización automática
  print('🚀 Iniciando app y SyncManager...');
  SyncManager().startAutoSync();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ferti-Go',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}