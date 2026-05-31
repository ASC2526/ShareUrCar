import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8080";

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
      body: jsonEncode({'email': email, 'password': password}),
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
      try {
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ?? body['error'] ?? "Error al registrar el vehículo",
        );
      } catch (_) {
        throw Exception("Error al registrar el vehículo");
      }
    }
  }

  static String get mapboxToken => dotenv.env['MAPBOX_TOKEN'] ?? '';

  static Future<List<Map<String, dynamic>>> getAddressSuggestions(
    String query,
  ) async {
    if (query.length < 3) return [];

    final url = Uri.parse(
      "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?country=es&proximity=-0.4810,38.3452&types=poi,address,place&access_token=$mapboxToken&limit=5",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'] ?? [];
        return features.map((f) {
          return {
            'name': f['place_name'],
            'lng': f['center'][0],
            'lat': f['center'][1],
          };
        }).toList();
      }
    } catch (e) {
      print("Error en Mapbox: $e");
    }
    return [];
  }

  static Future<List<dynamic>> searchRoutes(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final url = Uri.parse(
      "$baseUrl/routes/search?originLat=$originLat&originLng=$originLng&destLat=$destLat&destLng=$destLng",
    );
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
  static Future<void> joinRoute(int routeId, int userId, bool roundTrip) async {
    final url = Uri.parse(
      "$baseUrl/routes/$routeId/join/$userId?roundTrip=$roundTrip",
    );
    final response = await http.post(url);
    if (response.statusCode != 200) {
      String msg = "Error al unirse a la ruta";
      try {
        final body = json.decode(response.body);
        if (body is Map) {
          msg = body['error']?.toString() ?? body['message']?.toString() ?? msg;
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> joinMultipleRoutes(
    List<int> routeIds,
    int userId,
    bool roundTrip,
  ) async {
    final url = Uri.parse(
      "$baseUrl/routes/join-multiple/$userId?roundTrip=$roundTrip",
    );
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(routeIds),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    String msg = "Error al unirse a las rutas";
    try {
      final body = json.decode(response.body);
      if (body is Map) {
        msg = body['error']?.toString() ?? body['message']?.toString() ?? msg;
      }
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<Map<String, dynamic>> joinSeries(
    int routeId,
    int userId,
    bool roundTrip,
  ) async {
    final url = Uri.parse(
      "$baseUrl/routes/$routeId/join-series/$userId?roundTrip=$roundTrip",
    );
    final response = await http.post(url);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    String msg = "Error al unirse a la serie";
    try {
      final body = json.decode(response.body);
      if (body is Map) {
        msg = body['error']?.toString() ?? body['message']?.toString() ?? msg;
      }
    } catch (_) {}
    throw Exception(msg);
  }

  // info de la serie de una ruta por seriesId, totalRoutes, isSeries.
  static Future<Map<String, dynamic>> getSeriesInfo(int routeId) async {
    final url = Uri.parse("$baseUrl/routes/$routeId/series");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    throw Exception("Error obteniendo info de la serie");
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

  static Future<void> leaveRoute(int routeId, int userId) async {
    final url = Uri.parse("$baseUrl/routes/$routeId/leave/$userId");
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? "Error desconocido al abandonar");
      } catch (e) {
        throw Exception("Error al abandonar la ruta");
      }
    }
  }

  static Future<void> deleteRoute(int routeId) async {
    final url = Uri.parse("$baseUrl/routes/$routeId");
    final response = await http.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al cancelar la ruta");
    }
  }

  // buscador especializado en centros educativos
  static Future<List<Map<String, dynamic>>> getCenterSuggestions(
    String query,
  ) async {
    if (query.length < 3) return [];

    final url = Uri.parse(
      "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?country=es&types=poi&poi_category=education&access_token=$mapboxToken&limit=5",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'] ?? [];
        return features.map((f) => {'name': f['place_name']}).toList();
      }
    } catch (e) {
      print("Error buscando centros: $e");
    }
    return [];
  }

  static Future<bool> updateUserProfile(
    Map<String, dynamic> data,
    int userId,
  ) async {
    final url = Uri.parse("$baseUrl/users/$userId");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return true;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? "Error desconocido");
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/users/$userId"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("No se pudo obtener el usuario");
    }
  }

  static Future<int> getCompletedTripsCount(int userId) async {
    final url = Uri.parse("$baseUrl/routes/completed-count/$userId");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return int.parse(response.body);
    }
    return 0;
  }

  static Future<void> completeRoute(int routeId) async {
    final url = Uri.parse("$baseUrl/routes/$routeId/complete");
    final response = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode != 200) {
      throw Exception("Error al completar el viaje: ${response.body}");
    }
  }

  static Future<void> confirmParticipation(int routeId, int userId) async {
    final url = Uri.parse("$baseUrl/routes/$routeId/confirm/$userId");
    final response = await http.patch(url);
    if (response.statusCode != 200) {
      throw Exception("Error al confirmar: ${response.body}");
    }
  }

  static Future<List<dynamic>> getGroupMessages(int groupId) async {
    final url = Uri.parse("$baseUrl/messages/group/$groupId");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar los mensajes");
    }
  }

  static Future<void> sendMessage(Map<String, dynamic> messageData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/messages"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(messageData),
    );
    if (response.statusCode != 201) {
      throw Exception("Error al enviar el mensaje");
    }
  }

  static Future<List<dynamic>> getUserChats(int userId) async {
    final url = Uri.parse("$baseUrl/messages/user/$userId");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error al cargar los chats");
    }
  }

  static Future<int> getGroupIdByRoute(int routeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/messages/group-by-route/$routeId"),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error obteniendo grupo");
    }
  }

  static Future<List<dynamic>> getGroupMembers(int groupId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/messages/group-members/$groupId"),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error cargando miembros");
    }
  }

  static Future<Map<String, dynamic>> updateBalance(
    int userId,
    double amount,
  ) async {
    final url = Uri.parse("$baseUrl/users/$userId/balance?amount=$amount");
    final response = await http.patch(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Error actualizando saldo");
  }

  static Future<double> calculateRoutePrice(
    int routeId,
    int userId,
    bool roundTrip,
  ) async {
    final url = Uri.parse(
      "$baseUrl/routes/$routeId/price"
      "?userId=$userId"
      "&roundTrip=$roundTrip",
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['price'] as num).toDouble();
    }
    throw Exception("Error calculando precio");
  }

  static Future<void> createReview(
    int targetUserId,
    Map<String, dynamic> reviewData,
  ) async {
    final url = Uri.parse("$baseUrl/users/$targetUserId/reviews");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(reviewData),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error al guardar la reseña");
    }
  }

  static Future<List<dynamic>> getUserPayments(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/payments/user/$userId"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Error cargando pagos");
  }

  static Future<List<dynamic>> getSeriesRoutes(int routeId) async {
    final url = Uri.parse("$baseUrl/routes/$routeId/series-routes");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception("Error cargando rutas de la serie");
  }

  static Future<List<dynamic>> getNotifications(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/notifications/user/$userId"),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Error cargando notificaciones");
  }

  static Future<int> countUnreadNotifications(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/notifications/user/$userId/unread-count"),
    );
    if (response.statusCode == 200) {
      return int.tryParse(response.body) ?? 0;
    }
    return 0;
  }

  static Future<void> markNotificationsAsRead(int userId) async {
    await http.patch(
      Uri.parse("$baseUrl/notifications/user/$userId/mark-read"),
    );
  }

  static Future<void> reportIncident(
    int routeId,
    int reporterId,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/notifications/incident/$routeId/reporter/$reporterId",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );
    if (response.statusCode != 200) {
      String msg = "Error al reportar la incidencia";
      try {
        final body = jsonDecode(response.body);
        if (body is Map) msg = body['error']?.toString() ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
