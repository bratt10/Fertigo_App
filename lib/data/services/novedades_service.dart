import 'dart:convert';
import 'package:http/http.dart' as http;

class NovedadesService {
  static final String apiUrl = "http://192.168.137.34:8080/novedades";

  static Future<bool> enviarNovedad({
    required String nombre,
    required String finca,
    required String correo,
    required String novedad,
  }) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "nombreDeFinca": finca,
        "correo": correo,
        "novedad": novedad,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Error al enviar: ${response.body}');
    }
  }
}
