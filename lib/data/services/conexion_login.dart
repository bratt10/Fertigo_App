import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ferti_go/data/models/usuario_sesion.dart';

class ConexionLogin {
  static final String baseUrl = 'https://fertigo-production-0cf0.up.railway.app/app';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "contraseña": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      UsuarioSesion.guardarUsuario(data); // ✅ Guardamos el usuario activo
      return data;
    } else {
      throw Exception('Error: ${response.body}');
    }
  }
}
