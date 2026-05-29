import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'active_trip_screen.dart';

class AllRoutesScreen extends StatefulWidget {
  final List rutas;
  final Map user;

  const AllRoutesScreen({super.key, required this.rutas, required this.user});

  @override
  State<AllRoutesScreen> createState() => _AllRoutesScreenState();
}

class _AllRoutesScreenState extends State<AllRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List rutasOrdenadas = [];
  List rutasFiltradas = [];

  @override
  void initState() {
    super.initState();
    rutasOrdenadas = List.from(widget.rutas);
    rutasOrdenadas.sort((a, b) {
      final dA =
          DateTime.tryParse(a['travel_date']?.toString() ?? '') ??
          DateTime.now();
      final dB =
          DateTime.tryParse(b['travel_date']?.toString() ?? '') ??
          DateTime.now();
      return dA.compareTo(dB);
    });

    rutasFiltradas = rutasOrdenadas;
  }

  void _filtrar(String query) {
    setState(() {
      if (query.isEmpty) {
        rutasFiltradas = rutasOrdenadas;
      } else {
        rutasFiltradas = rutasOrdenadas.where((r) {
          final dest = (r['destination'] ?? '').toString().toLowerCase();
          final origin = (r['origin'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return dest.contains(q) || origin.contains(q);
        }).toList();
      }
    });
  }

  String _obtenerFecha(String? fechaIso) {
    if (fechaIso == null) return "Fecha sin definir";
    try {
      DateTime f = DateTime.parse(fechaIso);
      return DateFormat('EEEE, dd MMMM', 'es_ES').format(f);
    } catch (e) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Todos mis viajes",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: "Buscar origen o destino...",
                prefixIcon: Icon(Icons.search, color: Color(0xFF5F2C82)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF5F2C82)),
                ),
              ),
            ),
          ),

          // Lista de rutas
          Expanded(
            child: rutasFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 10),
                        Text("No se encontraron coincidencias"),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rutasFiltradas.length,
                    itemBuilder: (context, index) {
                      final ruta = rutasFiltradas[index];
                      final fecha = _obtenerFecha(ruta['travel_date']);
                      final pasajerosEnRuta =
                          (ruta['passengers'] as List?)?.length ?? 0;
                      final plazasTotales =
                          (ruta['available_seats'] ?? 0) + pasajerosEnRuta;
                      final hora =
                          ruta['departure_time']?.toString().substring(0, 5) ??
                          '--:--';

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Color(
                              0xFF5F2C82,
                            ).withValues(alpha: 0.1),
                            child: Icon(
                              Icons.directions_car,
                              color: Color(0xFF5F2C82),
                            ),
                          ),
                          title: Text(
                            "${ruta['origin']} → ${ruta['destination']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(fecha),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Salida: $hora",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    "Plazas: $pasajerosEnRuta/$plazasTotales",
                                    style: TextStyle(
                                      color: Color(0xFF49A09D),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActiveTripScreen(
                                  ruta: Map<String, dynamic>.from(ruta),
                                  user: widget.user,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
