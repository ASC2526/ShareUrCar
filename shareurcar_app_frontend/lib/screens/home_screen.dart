import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shareurcar_app_frontend/screens/active_trip_screen.dart';
import 'package:shareurcar_app_frontend/screens/create_route_screen.dart';
import 'package:shareurcar_app_frontend/screens/search_route_screen.dart';
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

  @override
  void initState() {
    super.initState();
    fetchMyRoutes();
  }

  void fetchMyRoutes() async {
    setState(() => isLoading = true);
    try {
      final rutas = await ApiService.getMyRoutes(widget.user['idUser'] ?? widget.user['id_user']); 
      setState(() {
        dynamicRoutes = rutas;
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _obtenerFechaRelativa(String? fechaIso) {
    if (fechaIso == null) return "Hoy"; // Fallback
    
    try {
      DateTime fechaRuta = DateTime.parse(fechaIso);
      DateTime hoy = DateTime.now();
      DateTime hoyMedianoche = DateTime(hoy.year, hoy.month, hoy.day);
      DateTime fechaRutaMedianoche = DateTime(fechaRuta.year, fechaRuta.month, fechaRuta.day);

      int diferenciaDias = fechaRutaMedianoche.difference(hoyMedianoche).inDays;

      if (diferenciaDias == 0) {
        return "Hoy";
      } else if (diferenciaDias == 1) {
        return "Mañana";
      } else if (diferenciaDias > 1 && diferenciaDias <= 7) {
        return "En $diferenciaDias días";
      } else {
        return DateFormat('dd MMM').format(fechaRuta);
      }
    } catch (e) {
      return "Próximamente";
    }
  }

  // Extraer iniciales si no hay foto
  String _obtenerIniciales(String nombre) {
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : "U";
  }

  @override
  Widget build(BuildContext context) {
    final hasTrips = dynamicRoutes.isNotEmpty;
    final String? fotoUrl = widget.user['profile_photo'];
    final String nombreUsuario = widget.user['firstname'] ?? 'Usuario';

    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bienvenido de nuevo,", style: TextStyle(color: Colors.white70)),
                        Text(
                          nombreUsuario,
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // notificaciones con foto de perfil
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none, color: Colors.white),
                          onPressed: () {
                            // abrir panel de notificaciones
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No tienes notificaciones nuevas")));
                          },
                        ),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                          child: fotoUrl == null 
                              ? Text(_obtenerIniciales(nombreUsuario), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateRouteScreen(user: widget.user))),
                        child: actionButton("Crear ruta", Icons.add, Color(0xFF42A5F5)),
                      )
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchRouteScreen(user: widget.user))),
                        child: actionButton("Buscar rutas", Icons.search, Color(0xFF7E57C2)),
                      )
                    ),
                  ],
                )
              ],
            ),
          ),

          SizedBox(height: 20),

          // lista viajes activos
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Viajes Activos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text("Ver todos", style: TextStyle(color: Color(0xFF5F2C82), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 15),
                  
                  if (isLoading)
                    Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF5F2C82))))
                  else if (hasTrips)
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(top: 0),
                        itemCount: dynamicRoutes.length,
                        itemBuilder: (context, index) {
                          final route = dynamicRoutes[index];
                          
                          final destino = route['destination'] ?? 'Destino Desconocido';
                          final hora = route['departure_time'] != null ? route['departure_time'].substring(0,5) : '00:00';
                          final fechaRelativa = _obtenerFechaRelativa(route['travel_date']); // ajustar backend para que devuelva esto
                          
                          // el backend deberá mandarnos el nombre del driver y las plazas totales
                          final driverName = route['driverName'] ?? "Alejandro Sánchez"; 
                          final plazasTotales = route['max_seats'] ?? 4; 
                          final plazasOcupadas = plazasTotales - (route['available_seats'] ?? 4);

                          return _buildTripCard(destino, hora, fechaRelativa, driverName, plazasOcupadas, plazasTotales);
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_filled_outlined, size: 60, color: Colors.grey.shade300),
                            SizedBox(height: 10),
                            Text("No tienes viajes activos", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // botones arriba
  Widget actionButton(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
        ],
      ),
    );
  }

  Widget _buildTripCard(String destino, String hora, String fechaRelativa, String driverName, int plazasOcupadas, int plazasTotales) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // buscamos la ruta completa usando el destino y la hora como referencia
            final rutaSeleccionada = dynamicRoutes.firstWhere((r) => r['destination'] == destino);
            
            final actualizaHome = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ActiveTripScreen(ruta: rutaSeleccionada, user: widget.user))
            );

            if (actualizaHome == true) {
              fetchMyRoutes();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // destino, fecha y hora
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.location_on, color: Colors.blue.shade600, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(destino, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                              SizedBox(width: 4),
                              Text("$fechaRelativa · $hora", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(20)), // Fondo azul clarito
                      child: Text(fechaRelativa, style: TextStyle(color: Color(0xFF5C6BC0), fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                
                SizedBox(height: 15),
                Divider(color: Colors.grey.shade200, height: 1),
                SizedBox(height: 15),

                // conductor y plazas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                        SizedBox(width: 8),
                        Text(driverName, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.group_outlined, size: 18, color: Color(0xFF5F2C82)),
                        SizedBox(width: 4),
                        Text("$plazasOcupadas/$plazasTotales", style: TextStyle(color: Color(0xFF5F2C82), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}