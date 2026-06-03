import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _base = "http://10.0.2.2:8080";

  static String get baseUrl => _base;
  static String get mapboxToken => dotenv.env['MAPBOX_TOKEN'] ?? '';

  // helper para errores
  static String _extractError(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        return body['error']?.toString() ??
            body['message']?.toString() ??
            fallback;
      }
    } catch (_) {}
    return fallback;
  }

  static Never _throw(http.Response res, String fallback) =>
      throw Exception(_extractError(res, fallback));

  // AUTH
  static Future<dynamic> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? 'Credenciales incorrectas');
  }

  static Future<void> register(Map<String, dynamic> user) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
    if (res.statusCode != 201) _throw(res, "Error al registrar");
  }

  // USUARIOS
  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final res = await http.get(Uri.parse("$_base/users/$userId"));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    _throw(res, "No se pudo obtener el usuario");
  }

  static Future<bool> updateUserProfile(
    Map<String, dynamic> data,
    int userId,
  ) async {
    final res = await http.put(
      Uri.parse("$_base/users/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return true;
    _throw(res, "Error al actualizar el perfil");
  }

  // subir foto en base64
  static Future<String> uploadPhoto(int userId, String base64Photo) async {
    final res = await http.post(
      Uri.parse("$_base/users/$userId/photo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"photo": base64Photo}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['profile_photo']?.toString() ?? '';
    }
    _throw(res, "Error al subir la foto");
  }

  static Future<Map<String, dynamic>> updateBalance(
    int userId,
    double amount,
  ) async {
    final res = await http.patch(
      Uri.parse("$_base/users/$userId/balance?amount=$amount"),
    );
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    _throw(res, "Error actualizando saldo");
  }

  static Future<List<dynamic>> getUserReviews(int userId) async {
    final res = await http.get(Uri.parse("$_base/users/$userId/reviews"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error al cargar las reseñas");
  }

  static Future<void> createReview(
    int targetUserId,
    Map<String, dynamic> reviewData,
  ) async {
    final res = await http.post(
      Uri.parse("$_base/users/$targetUserId/reviews"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(reviewData),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _throw(res, "Error al guardar la reseña");
    }
  }

  // RUTAS
  static Future<List<dynamic>> getMyRoutes(int userId) async {
    final res = await http.get(Uri.parse("$_base/routes/my-routes/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error al cargar tus rutas");
  }

  static Future<void> createRoute(Map<String, dynamic> routeData) async {
    final res = await http.post(
      Uri.parse('$_base/routes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(routeData),
    );
    if (res.statusCode != 201) _throw(res, "Error al crear ruta");
  }

  static Future<List<dynamic>> searchRoutes(
    double oLat,
    double oLng,
    double dLat,
    double dLng,
  ) async {
    final res = await http.get(
      Uri.parse(
        "$_base/routes/search?originLat=$oLat&originLng=$oLng&destLat=$dLat&destLng=$dLng",
      ),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error al buscar las rutas");
  }

  static Future<void> joinRoute(int routeId, int userId, bool roundTrip) async {
    final res = await http.post(
      Uri.parse("$_base/routes/$routeId/join/$userId?roundTrip=$roundTrip"),
    );
    if (res.statusCode != 200) _throw(res, "Error al unirse a la ruta");
  }

  static Future<Map<String, dynamic>> joinMultipleRoutes(
    List<int> routeIds,
    int userId,
    bool roundTrip,
  ) async {
    final res = await http.post(
      Uri.parse("$_base/routes/join-multiple/$userId?roundTrip=$roundTrip"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(routeIds),
    );
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    _throw(res, "Error al unirse a las rutas");
  }

  static Future<Map<String, dynamic>> joinSeries(
    int routeId,
    int userId,
    bool roundTrip,
  ) async {
    final res = await http.post(
      Uri.parse(
        "$_base/routes/$routeId/join-series/$userId?roundTrip=$roundTrip",
      ),
    );
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    _throw(res, "Error al unirse a la serie");
  }

  static Future<Map<String, dynamic>> getSeriesInfo(int routeId) async {
    final res = await http.get(Uri.parse("$_base/routes/$routeId/series"));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    _throw(res, "Error obteniendo info de la serie");
  }

  static Future<List<dynamic>> getSeriesRoutes(int routeId) async {
    final res = await http.get(
      Uri.parse("$_base/routes/$routeId/series-routes"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error cargando rutas de la serie");
  }

  static Future<void> leaveRoute(int routeId, int userId) async {
    final res = await http.delete(
      Uri.parse("$_base/routes/$routeId/leave/$userId"),
    );
    if (res.statusCode != 200) _throw(res, "Error al abandonar la ruta");
  }

  static Future<void> deleteRoute(int routeId) async {
    final res = await http.delete(Uri.parse("$_base/routes/$routeId"));
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, "Error al cancelar la ruta");
    }
  }

  static Future<void> completeRoute(int routeId) async {
    final res = await http.patch(
      Uri.parse("$_base/routes/$routeId/complete"),
      headers: {"Content-Type": "application/json"},
    );
    if (res.statusCode != 200) _throw(res, "Error al completar el viaje");
  }

  static Future<void> confirmParticipation(int routeId, int userId) async {
    final res = await http.patch(
      Uri.parse("$_base/routes/$routeId/confirm/$userId"),
    );
    if (res.statusCode != 200) _throw(res, "Error al confirmar");
  }

  static Future<int> getCompletedTripsCount(int userId) async {
    final res = await http.get(
      Uri.parse("$_base/routes/completed-count/$userId"),
    );
    if (res.statusCode == 200) return int.tryParse(res.body) ?? 0;
    return 0;
  }

  static Future<double> calculateRoutePrice(
    int routeId,
    int userId,
    bool roundTrip,
  ) async {
    final res = await http.get(
      Uri.parse(
        "$_base/routes/$routeId/price?userId=$userId&roundTrip=$roundTrip",
      ),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['price'] as num).toDouble();
    }
    _throw(res, "Error calculando precio");
  }

  // CONDUCTOR
  static Future<void> registerDriver(Map<String, dynamic> driverData) async {
    final res = await http.post(
      Uri.parse('$_base/drivers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(driverData),
    );
    if (res.statusCode != 201) _throw(res, "Error al registrar el vehículo");
  }

  // CHATS
  static Future<List<dynamic>> getGroupMessages(int groupId) async {
    final res = await http.get(Uri.parse("$_base/messages/group/$groupId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error al cargar los mensajes");
  }

  static Future<void> sendMessage(Map<String, dynamic> messageData) async {
    final res = await http.post(
      Uri.parse("$_base/messages"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(messageData),
    );
    if (res.statusCode != 201) _throw(res, "Error al enviar el mensaje");
  }

  static Future<List<dynamic>> getUserChats(int userId) async {
    final res = await http.get(Uri.parse("$_base/messages/user/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error al cargar los chats");
  }

  static Future<int> getGroupIdByRoute(int routeId) async {
    final res = await http.get(
      Uri.parse("$_base/messages/group-by-route/$routeId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error obteniendo grupo");
  }

  static Future<List<dynamic>> getGroupMembers(int groupId) async {
    final res = await http.get(
      Uri.parse("$_base/messages/group-members/$groupId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error cargando miembros");
  }

  // PAGOS
  static Future<List<dynamic>> getUserPayments(int userId) async {
    final res = await http.get(Uri.parse("$_base/payments/user/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error cargando pagos");
  }

  // NOTIF
  static Future<List<dynamic>> getNotifications(int userId) async {
    final res = await http.get(Uri.parse("$_base/notifications/user/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    _throw(res, "Error cargando notificaciones");
  }

  static Future<int> countUnreadNotifications(int userId) async {
    final res = await http.get(
      Uri.parse("$_base/notifications/user/$userId/unread-count"),
    );
    if (res.statusCode == 200) return int.tryParse(res.body) ?? 0;
    return 0;
  }

  static Future<void> markNotificationsAsRead(int userId) async {
    await http.patch(Uri.parse("$_base/notifications/user/$userId/mark-read"));
  }

  static Future<void> reportIncident(
    int routeId,
    int reporterId,
    String message,
  ) async {
    final res = await http.post(
      Uri.parse("$_base/notifications/incident/$routeId/reporter/$reporterId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );
    if (res.statusCode != 200) _throw(res, "Error al reportar la incidencia");
  }

  // MAPBOX
  static Future<List<Map<String, dynamic>>> getAddressSuggestions(
    String query,
  ) async {
    if (query.length < 3) return [];
    try {
      final res = await http.get(
        Uri.parse(
          "https://api.mapbox.com/geocoding/v5/mapbox.places/"
          "${Uri.encodeComponent(query)}.json"
          "?country=es&proximity=-0.4810,38.3452"
          "&types=poi,address,place&access_token=$mapboxToken&limit=5",
        ),
      );
      if (res.statusCode == 200) {
        final List features = jsonDecode(res.body)['features'] ?? [];
        return features
            .map(
              (f) => {
                'name': f['place_name'],
                'lng': f['center'][0],
                'lat': f['center'][1],
              },
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> getCenterSuggestions(
    String query,
  ) async {
    if (query.length < 3) return [];
    try {
      final res = await http.get(
        Uri.parse(
          "https://api.mapbox.com/geocoding/v5/mapbox.places/"
          "${Uri.encodeComponent(query)}.json"
          "?country=es&types=poi&poi_category=education"
          "&access_token=$mapboxToken&limit=5",
        ),
      );
      if (res.statusCode == 200) {
        final List features = jsonDecode(res.body)['features'] ?? [];
        return features.map((f) => {'name': f['place_name']}).toList();
      }
    } catch (_) {}
    return [];
  }
}
