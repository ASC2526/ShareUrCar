import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shareurcar_app_frontend/screens/active_trip_screen.dart';
import 'package:shareurcar_app_frontend/screens/all_routes_screen.dart';
import 'package:shareurcar_app_frontend/screens/create_route_screen.dart';
import 'package:shareurcar_app_frontend/screens/login_screen.dart';
import 'package:shareurcar_app_frontend/screens/search_route_screen.dart';
import 'package:shareurcar_app_frontend/screens/wallet_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Map user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List dynamicRoutes = [];
  bool isLoading = true;
  late Map currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshUser();
    fetchMyRoutes();
  }

  Future<void> _refreshUser() async {
    try {
      final updatedUser = await ApiService.getUserById(currentUser['idUser']);
      if (mounted) setState(() => currentUser = updatedUser);
    } catch (e) {
      debugPrint("Error refrescando usuario: $e");
    }
  }

  void fetchMyRoutes() async {
    setState(() => isLoading = true);
    try {
      final rutas = await ApiService.getMyRoutes(
        currentUser['idUser'] ?? currentUser['id_user'],
      );
      setState(() => dynamicRoutes = rutas);
    } catch (e) {
      debugPrint("Error fetchMyRoutes: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Devuelve las rutas de los próximos 7 días desde la más cercana
  List _filtrarRutasSemana(List todas) {
    if (todas.isEmpty) return [];

    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);

    final futuras = todas.where((r) {
      if (r['travel_date'] == null) return false;
      final d = DateTime.tryParse(r['travel_date'].toString());
      if (d == null) return false;
      return !d.isBefore(inicioDia);
    }).toList();

    if (futuras.isEmpty) return [];

    futuras.sort((a, b) {
      final dA =
          DateTime.tryParse(a['travel_date'].toString()) ?? DateTime.now();
      final dB =
          DateTime.tryParse(b['travel_date'].toString()) ?? DateTime.now();
      return dA.compareTo(dB);
    });

    final primeraFecha =
        DateTime.tryParse(futuras.first['travel_date'].toString()) ?? inicioDia;
    final finSemana = primeraFecha.add(const Duration(days: 6));

    return futuras.where((r) {
      final d =
          DateTime.tryParse(r['travel_date'].toString()) ?? DateTime.now();
      return !d.isAfter(finSemana);
    }).toList();
  }

  String _obtenerFechaRelativa(String? fechaIso) {
    if (fechaIso == null) return "Hoy";
    try {
      final fechaRuta = DateTime.parse(fechaIso);
      final hoy = DateTime.now();
      final hoyMN = DateTime(hoy.year, hoy.month, hoy.day);
      final rutaMN = DateTime(fechaRuta.year, fechaRuta.month, fechaRuta.day);
      final diff = rutaMN.difference(hoyMN).inDays;

      if (diff == 0) return "Hoy";
      if (diff == 1) return "Mañana";
      if (diff > 1 && diff <= 7) return "En $diff días";
      return DateFormat('dd MMM').format(fechaRuta);
    } catch (_) {
      return "Próximamente";
    }
  }

  String _obtenerIniciales(String nombre) =>
      nombre.isNotEmpty ? nombre[0].toUpperCase() : "U";

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String? fotoUrl = currentUser['profile_photo'];
    final String nombreUsuario = currentUser['firstname'] ?? 'Usuario';
    final rutasSemana = _filtrarRutasSemana(dynamicRoutes);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ── CABECERA ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila usuario + avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bienvenido de nuevo,",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          nombreUsuario,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "No tienes notificaciones nuevas",
                                ),
                              ),
                            );
                          },
                        ),
                        PopupMenuButton<String>(
                          offset: const Offset(0, 45),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (value) {
                            if (value == "logout") {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: "logout",
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Cerrar sesión",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            backgroundImage: fotoUrl != null
                                ? NetworkImage(fotoUrl)
                                : null,
                            child: fotoUrl == null
                                ? Text(
                                    _obtenerIniciales(nombreUsuario),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ── TARJETA SALDO ─────────────────────────────
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WalletScreen(user: currentUser),
                      ),
                    );
                    await _refreshUser();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Saldo disponible",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${(((currentUser['balance'] ?? 0) - (currentUser['heldBalance'] ?? currentUser['held_balance'] ?? 0))).toStringAsFixed(2)} €",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ── BOTONES CREAR / BUSCAR ────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateRouteScreen(user: currentUser),
                            ),
                          );
                          await _refreshUser();
                          fetchMyRoutes();
                        },
                        child: _actionButton(
                          "Crear ruta",
                          Icons.add,
                          const Color(0xFF42A5F5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SearchRouteScreen(user: currentUser),
                            ),
                          );
                          await _refreshUser();
                          fetchMyRoutes();
                        },
                        child: _actionButton(
                          "Buscar rutas",
                          Icons.search,
                          const Color(0xFF7E57C2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── LISTA DE VIAJES ───────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera sección
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Viajes de esta semana",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllRoutesScreen(
                                rutas: dynamicRoutes,
                                user: currentUser,
                              ),
                            ),
                          ).then((_) => fetchMyRoutes());
                        },
                        child: const Text(
                          "Ver todos",
                          style: TextStyle(
                            color: Color(0xFF5F2C82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Contenido
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5F2C82),
                            ),
                          )
                        : rutasSemana.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car_filled_outlined,
                                  size: 60,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  dynamicRoutes.isEmpty
                                      ? "No tienes viajes activos"
                                      : "No tienes viajes esta semana",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: rutasSemana.length,
                            itemBuilder: (context, index) {
                              final ruta = rutasSemana[index];
                              return _buildTripCard(
                                Map<String, dynamic>.from(ruta),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS AUXILIARES ──────────────────────────────────
  Widget _actionButton(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> ruta) {
    final destino = ruta['destination'] ?? 'Destino';

    final hora = (ruta['departure_time'] ?? '00:00:00').toString().length >= 5
        ? ruta['departure_time'].toString().substring(0, 5)
        : '00:00';

    final horaVuelta =
        ruta['return_time'] != null &&
            ruta['return_time'].toString().length >= 5
        ? ruta['return_time'].toString().substring(0, 5)
        : null;

    final fechaRelativa = _obtenerFechaRelativa(
      ruta['travel_date']?.toString(),
    );
    final driverName = ruta['driverName'] ?? "Conductor";

    // Plazas: pasajeros ocupados vs total del coche
    final List pasajeros = (ruta['passengers'] as List?) ?? [];
    final int plazasOcupadas = pasajeros.length;
    final int plazasDisponibles = (ruta['available_seats'] ?? 0) as int;
    final int plazasTotales = plazasOcupadas + plazasDisponibles;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final actualiza = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveTripScreen(ruta: ruta, user: currentUser),
              ),
            );
            await _refreshUser();
            if (actualiza == true) fetchMyRoutes();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Destino + hora + badge fecha
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destino,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  horaVuelta != null
                                      ? "Salida: $hora · Vuelta: $horaVuelta"
                                      : "Salida: $hora",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        fechaRelativa,
                        style: const TextStyle(
                          color: Color(0xFF5C6BC0),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 15),

                // Conductor + plazas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          driverName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          size: 18,
                          color: Color(0xFF5F2C82),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$plazasOcupadas/$plazasTotales",
                          style: const TextStyle(
                            color: Color(0xFF5F2C82),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
