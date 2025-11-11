import 'package:ferti_go/data/models/solicitud_fertilizante.dart';
import 'package:ferti_go/data/models/usuario_sesion.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SolicitudFertilizanteService {
  static final String baseUrl = "http://192.168.137.34:8080";

  Future<List<String>> obtenerTiposFertilizantes() async {
    final response = await http.get(Uri.parse('$baseUrl/fertilizante'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['nombre'].toString()).toList();
    } else {
      throw Exception("Error al cargar fertilizantes");
    }
  }

  Future<void> enviarSolicitud(SolicitudFertilizante solicitud) async {
    final idUsuario = UsuarioSesion.id;
    if (idUsuario == null) throw Exception("Usuario no autenticado");

    final response = await http.post(
      Uri.parse('$baseUrl/solicitudFertilizante/$idUsuario'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(solicitud.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al enviar solicitud: ${response.body}");
    }
  }
}
