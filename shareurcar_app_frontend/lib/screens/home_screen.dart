import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/create_route_screen.dart';
import 'package:shareurcar_app_frontend/screens/search_route_screen.dart';
import 'package:shareurcar_app_frontend/screens/profile_screen.dart'; // Importar perfil
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
      final rutas = await ApiService.getMyRoutes(widget.user['idUser']); 
      setState(() {
        dynamicRoutes = rutas;
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTrips = dynamicRoutes.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // HEADER SUPERIOR
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
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
                        Text("Bienvenido de nuevo,",
                            style: TextStyle(color: Colors.white70)),
                        Text(
                          widget.user['firstname'] ?? 'Usuario',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // AQUÍ ESTÁ EL CAMBIO DEL BOTÓN DE PERFIL
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CreateRouteScreen(user: widget.user)),
                          );
                        },
                        child: actionButton(
                          "Crear ruta",
                           Icons.add,
                          Colors.lightBlueAccent,
                        ),
                      )
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SearchRouteScreen(user: widget.user)),
                          );
                        },
                        child: actionButton(
                          "Buscar rutas",
                          Icons.search,
                          Colors.deepPurpleAccent,
                        ),
                      )
                    ),
                  ],
                )
              ],
            ),
          ),

          SizedBox(height: 20),

          // LISTA VIAJES ACTIVOS
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Viajes activos",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Ver todos", style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 10),
                  
                  if (isLoading)
                    Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (hasTrips)
                    Expanded(
                      child: ListView.builder(
                        itemCount: dynamicRoutes.length,
                        itemBuilder: (context, index) {
                          final route = dynamicRoutes[index];
                          return tripCard(
                            "${route['origin']} - ${route['destination']}",
                            route['departure_time'] ?? 'Hora no definida',
                            "Plazas libres: ${route['available_seats']}",
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Text(
                          "No hay viajes activos ahora mismo",
                          style: TextStyle(color: Colors.grey),
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

  // BOTONES
  Widget actionButton(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(height: 5),
          Text(text, style: TextStyle(color: Colors.white))
        ],
      ),
    );
  }

  // CARD VIAJE
  Widget tripCard(String title, String time, String seatsInfo) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(Icons.location_on, color: Colors.blue),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("Salida: $time"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 18, color: Colors.grey.shade700),
            SizedBox(height: 4),
            Text(seatsInfo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}