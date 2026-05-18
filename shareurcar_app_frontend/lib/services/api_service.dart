import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8080"; // Android emulator

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/users"));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar usuarios");
    }
  }

  static Future<void> createUser(Map<String, dynamic> user) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(user),
    );

    if (response.statusCode != 201) {
      throw Exception("Error al crear usuario");
    }
  }

  static Future<dynamic> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  static Future<void> register(Map<String, dynamic> user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );

    if (response.statusCode != 201) {
      throw Exception("Error al registrar");
    }
  }

  static Future<List<dynamic>> getRoutes() async {
    final response = await http.get(Uri.parse("$baseUrl/routes"));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar rutas");
    }
  }

  static Future<void> createRoute(Map<String, dynamic> routeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/routes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(routeData),
    );

    if (response.statusCode != 201) {
      throw Exception("Error al crear ruta: ${response.body}");
    }
  }

  static Future<void> registerDriver(Map<String, dynamic> driverData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/drivers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(driverData),
    );

    if (response.statusCode != 201) {
      throw Exception("Error al registrar el vehículo. Comprueba los datos.");
    }
  }

  static Future<List<String>> getAddressSuggestions(String query) async {
    if (query.trim().length < 3) return []; // No busca hasta que haya 3 letras
    
    // Filtramos por país (es) para que priorice calles y centros de aquí
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=es");

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'shareurcar_app_frontend' // OpenStreetMap exige un identificador
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        // Mapeamos los resultados para quedarnos solo con el texto de la dirección
        return data.map((item) => item['display_name'].toString()).toList();
      }
    } catch (e) {
      print("Error en autocompletado: $e");
    }
    return [];
  }

}