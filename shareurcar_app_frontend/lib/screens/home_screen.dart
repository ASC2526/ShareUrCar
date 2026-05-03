import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final Map user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final List trips = [];

    final hasTrips = trips.isNotEmpty; 

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
                          user['firstname'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    )
                  ],
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: actionButton(
                        "Crear ruta",
                        Icons.add,
                        Colors.lightBlueAccent,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: actionButton(
                        "Buscar rutas",
                        Icons.search,
                        Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          SizedBox(height: 20),

          // LISTA VIAJES
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
                      Text("Ver todos",
                          style: TextStyle(color: Colors.blue)),
                    ],
                  ),

                  SizedBox(height: 10),

                  hasTrips
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: trips.length,
                          itemBuilder: (context, index) {
                            final trip = trips[index];

                            return tripCard(
                              trip['origin'],
                              trip['date'],
                              trip['driver'],
                              "${trip['occupied']}/${trip['seats']}",
                            );
                          },
                        ),
                      )
                    : Expanded(
                        child: Center(
                          child: Text(
                            "No hay viajes activos",
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

  // 🔘 BOTONES
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

  // 🚗 CARD VIAJE
  Widget tripCard(String title, String time, String driver, String seats) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(Icons.location_on, color: Colors.blue),
        title: Text(title),
        subtitle: Text(time),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 18),
            Text(seats)
          ],
        ),
      ),
    );
  }
}