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

  static Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    if (query.trim().length < 3) return [];
    
    // forzamos la búsqueda en Alicante si el usuario no lo ha escrito
    String searchQuery = query;
    if (!query.toLowerCase().contains("alicante")) {
      searchQuery = "$query, Alicante";
    }

    final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=5&addressdetails=1&countrycodes=es");

    try {
final response = await http.get(url, headers: {
  'User-Agent': 'ShareUrCarApp_Project/1.0' 
});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => {
          "name": item['display_name'].toString(),
          "lat": double.parse(item['lat']),
          "lng": double.parse(item['lon']),
        }).toList();
      }
    } catch (e) {
      print("Error en autocompletado: $e");
    }
    return [];
  }

  static Future<List<dynamic>> searchRoutes(double originLat, double originLng, double destLat, double destLng) async {
    final url = Uri.parse("$baseUrl/routes/search?originLat=$originLat&originLng=$originLng&destLat=$destLat&destLng=$destLng");
    final response = await http.get(url);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception("Error al buscar las rutas");
  }

  // Cargar solo las rutas donde el usuario es conductor o pasajero
  static Future<List<dynamic>> getMyRoutes(int userId) async {
    final url = Uri.parse("$baseUrl/routes/my-routes/$userId");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar tus rutas");
    }
  }

  // Unirse a una ruta
  static Future<void> joinRoute(int routeId, int userId) async {
    final url = Uri.parse("$baseUrl/routes/$routeId/join/$userId");
    final response = await http.post(url);
    
    if (response.statusCode != 200) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? "Error desconocido al unirse");
      } catch (e) {
        throw Exception("Error al unirse a la ruta");
      }
    }
  }

  static Future<List<dynamic>> getUserReviews(int userId) async {
    final url = Uri.parse("$baseUrl/users/$userId/reviews");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar las reseñas");
    }
  }

}