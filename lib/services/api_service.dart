import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ── AUTH ──────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': correo, 'password': contrasena}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Correo o contraseña incorrectos');
    }
  }

  static Future<void> registrar(Map<String, dynamic> datos) async {
  final response = await http.post(
    Uri.parse('$baseUrl/usuarios/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(datos),
  );

  if (response.statusCode != 201) {
    throw Exception('Error al registrar');
  }
  }

  // ── EVENTOS ───────────────────────────────────────
  static Future<List<dynamic>> getEventos() async {
    final response = await http.get(Uri.parse('$baseUrl/eventos/'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar eventos');
    }
  }

  static Future<void> crearEvento(Map<String, dynamic> datos, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eventos/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',   // ← JWT aquí
      },
      body: jsonEncode(datos),
    );

/*     print('Status Code: ${response.statusCode}') para comprobar;
    print('Response Body: ${response.body}'); */

    if (response.statusCode != 201) {
      throw Exception('Error al crear evento');
    }
  }

  // Editar evento (admin)
  static Future<void> editarEvento(int id, Map<String, dynamic> data, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/eventos/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al editar evento');
    }
  }

  // Eliminar evento (admin)
  static Future<void> eliminarEvento(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/eventos/$id/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar evento');
    }
  }
  

  // ── ACADEMIAS ─────────────────────────────────────
  // ── ACADEMIAS ─────────────────────────────────────
static Future<List<dynamic>> getAcademias() async {
  final response = await http.get(Uri.parse('$baseUrl/academias/'));
  if (response.statusCode == 200) return jsonDecode(response.body);
  throw Exception('Error al cargar academias');
}

static Future<void> crearAcademia(Map<String, dynamic> datos, String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/academias/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(datos),
  );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
  if (response.statusCode != 201) throw Exception('Error al crear academia');
}

static Future<void> editarAcademia(int id, Map<String, dynamic> datos, String token) async {
  final response = await http.put(
    Uri.parse('$baseUrl/academias/$id/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(datos),
  );
  if (response.statusCode != 200) throw Exception('Error al editar academia');
}

static Future<void> eliminarAcademia(int id, String token) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/academias/$id/'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 204) throw Exception('Error al eliminar academia');
}

  
}