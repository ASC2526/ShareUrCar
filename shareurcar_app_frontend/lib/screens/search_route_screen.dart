import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shareurcar_app_frontend/screens/route_details_screen.dart';
import '../services/api_service.dart';
import 'create_route_screen.dart';
import 'dart:async';

class SearchRouteScreen extends StatefulWidget {
  final Map user;

  const SearchRouteScreen({super.key, required this.user});

  @override
  _SearchRouteScreenState createState() => _SearchRouteScreenState();
}

class _SearchRouteScreenState extends State<SearchRouteScreen> {
  final originController = TextEditingController();
  final destinationController = TextEditingController();

  List<Map<String, dynamic>> originSuggestions = [];
  List<Map<String, dynamic>> destinationSuggestions = [];

  double? selectedOriginLat;
  double? selectedOriginLng;
  double? selectedDestLat;
  double? selectedDestLng;

  bool isLoading = false;
  Timer? _debounce;
  List<dynamic> rutasEncontradas = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void buscarRutas() async {
    if (selectedOriginLat == null || selectedDestLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Por favor, selecciona un origen y destino de la lista de sugerencias",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final resultados = await ApiService.searchRoutes(
        selectedOriginLat!,
        selectedOriginLng!,
        selectedDestLat!,
        selectedDestLng!,
      );

      resultados.sort((a, b) {
        DateTime fechaA = DateTime.parse(a['travel_date'].toString());
        DateTime fechaB = DateTime.parse(b['travel_date'].toString());

        return fechaA.compareTo(fechaB);
      });

      setState(() {
        rutasEncontradas = resultados
            .where((r) => r['status'] != 'COMPLETED')
            .toList();
      });

      if (mounted) {
        _mostrarResultadosBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _mostrarResultadosBottomSheet() {
    // Función auxiliar para limpiar el texto y quitar ", Alicante"
    String limpiarDireccion(String direccion) {
      return direccion.replaceAll(", Alicante", "").trim();
    }

    // Función auxiliar para quitar los segundos de la hora
    String formatearHora(String hora) {
      return hora.length >= 5 ? hora.substring(0, 5) : hora;
    }

    final rutasVisibles = rutasEncontradas
        .where((r) => r['status'] != 'COMPLETED')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.fromLTRB(20, 15, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Text(
                "Rutas disponibles (${rutasVisibles.length})",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 15),

              rutasEncontradas.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Text(
                          "No hay rutas cercanas para este trayecto.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: rutasEncontradas.length,
                        itemBuilder: (context, index) {
                          final ruta = rutasVisibles[index];
                          final currentUserId =
                              widget.user['idUser'] ??
                              widget.user['id_user'] ??
                              widget.user['id'];
                          final driverId =
                              ruta['idDriver'] ??
                              ruta['id_driver'] ??
                              ruta['id_driver_id'];

                          bool esMiRuta = driverId == currentUserId;
                          bool yaUnido = false;

                          if (ruta['passengers'] != null) {
                            yaUnido = (ruta['passengers'] as List).any((p) {
                              final pid =
                                  p['idUser'] ?? p['id_user'] ?? p['id'];
                              return pid == currentUserId;
                            });
                          }
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hora y Plazas
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${formatearFechaCompleta(ruta['travel_date'])} · "
                                            "${obtenerFechaRelativa(ruta['travel_date'])}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),

                                          SizedBox(height: 6),

                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 20,
                                                color: Color(0xFF5F2C82),
                                              ),

                                              SizedBox(width: 8),

                                              Text(
                                                formatearHora(
                                                  ruta['departure_time']
                                                      .toString(),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.airline_seat_recline_normal,
                                              size: 16,
                                              color: Colors.green.shade700,
                                            ),

                                            SizedBox(width: 4),

                                            Text(
                                              "${ruta['available_seats']} libres",
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 20),
                                  // origen y Destino
                                  Row(
                                    children: [
                                      Column(
                                        children: [
                                          Icon(
                                            Icons.radio_button_checked,
                                            size: 16,
                                            color: Colors.blue.shade600,
                                          ),
                                          Container(
                                            height: 22,
                                            width: 2,
                                            color: Colors.grey.shade300,
                                          ),
                                          Icon(
                                            Icons.location_on,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              limpiarDireccion(ruta['origin']),
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 18),
                                            Text(
                                              limpiarDireccion(
                                                ruta['destination'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 15),

                                  Row(
                                    children: [
                                      if (ruta['pref_no_talk'] == true ||
                                          ruta['pref_no_talk'] == 1)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Tooltip(
                                            message: "Sin conversar",
                                            child: Text(
                                              "😶",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                      if (ruta['pref_luggage'] == true ||
                                          ruta['pref_luggage'] == 1)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Tooltip(
                                            message: "Equipaje permitido",
                                            child: Text(
                                              "💼",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                      if (ruta['pref_music'] == true ||
                                          ruta['pref_music'] == 1)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Tooltip(
                                            message: "Música durante el viaje",
                                            child: Text(
                                              "🎵",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                      if (ruta['pref_smoke'] == true ||
                                          ruta['pref_smoke'] == 1)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Tooltip(
                                            message: "Fumar permitido",
                                            child: Text(
                                              "🚬",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  SizedBox(height: 10),

                                  // conductor y Botón
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final seUnio = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RouteDetailsScreen(
                                                    ruta: ruta,
                                                    user: widget.user,
                                                  ),
                                            ),
                                          );
                                          if (seUnio == true && mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 4.0,
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Color(
                                                  0xFF5F2C82,
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 18,
                                                  color: Color(0xFF5F2C82),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                "Ver detalles",
                                                style: TextStyle(
                                                  color: Color(0xFF5F2C82),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Botón Unirse
                                      esMiRuta
                                          ? Text(
                                              "Tu ruta",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          : yaUnido
                                          ? Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  "Ya unido",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xFF49A09D,
                                                ),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 10,
                                                ),
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                final seUnio =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            RouteDetailsScreen(
                                                              ruta: ruta,
                                                              user: widget.user,
                                                            ),
                                                      ),
                                                    );
                                                if (seUnio == true && mounted) {
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: Text(
                                                "Unirse",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  String obtenerFechaRelativa(String? fechaIso) {
    if (fechaIso == null) return "Hoy";

    try {
      final fechaRuta = DateTime.parse(fechaIso);
      final hoy = DateTime.now();
      final hoyMN = DateTime(hoy.year, hoy.month, hoy.day);
      final rutaMN = DateTime(fechaRuta.year, fechaRuta.month, fechaRuta.day);
      final diff = rutaMN.difference(hoyMN).inDays;

      if (diff == 0) return "Hoy";
      if (diff == 1) return "Mañana";
      if (diff > 1) return "En $diff días";

      return "";
    } catch (_) {
      return "";
    }
  }

  String formatearFechaCompleta(String? fechaIso) {
    if (fechaIso == null) return "";

    try {
      final fecha = DateTime.parse(fechaIso);

      const dias = [
        "Lunes",
        "Martes",
        "Miércoles",
        "Jueves",
        "Viernes",
        "Sábado",
        "Domingo",
      ];

      return "${dias[fecha.weekday - 1]} "
          "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: Text(
          "Buscar ruta",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateRouteScreen(user: widget.user),
            ),
          );
        },
        backgroundColor: Color(0xFF5F2C82),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Crear ruta", style: TextStyle(color: Colors.white)),
      ),

      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: originController,
                  decoration: _inputDeco(
                    "Origen",
                    Icon(Icons.circle, color: Colors.blue.shade600, size: 16),
                  ),
                  onChanged: (val) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(Duration(milliseconds: 600), () async {
                      final sug = await ApiService.getAddressSuggestions(val);
                      if (mounted) setState(() => originSuggestions = sug);
                    });
                  },
                ),
                if (originSuggestions.isNotEmpty)
                  _buildSuggestions(originSuggestions, originController, (
                    lat,
                    lng,
                  ) {
                    selectedOriginLat = lat;
                    selectedOriginLng = lng;
                  }),

                SizedBox(height: 10),

                TextFormField(
                  controller: destinationController,
                  decoration: _inputDeco(
                    "Destino",
                    Icon(Icons.location_on, color: Colors.red, size: 20),
                  ),
                  onChanged: (val) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(Duration(milliseconds: 600), () async {
                      final sug = await ApiService.getAddressSuggestions(val);
                      if (mounted) setState(() => destinationSuggestions = sug);
                    });
                  },
                ),
                if (destinationSuggestions.isNotEmpty)
                  _buildSuggestions(
                    destinationSuggestions,
                    destinationController,
                    (lat, lng) {
                      selectedDestLat = lat;
                      selectedDestLng = lng;
                    },
                  ),

                SizedBox(height: 15),

                isLoading
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: buscarRutas,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF49A09D),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Buscar rutas",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(38.3452, -0.4810), // centrado en alicante
                initialZoom: 13.0,
                cameraConstraint: CameraConstraint.contain(
                  // para que no se pueda scrollear por todo el mundo
                  bounds: LatLngBounds(LatLng(37.5, -1.5), LatLng(39.0, 0.5)),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                  additionalOptions: {'accessToken': ApiService.mapboxToken},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, Icon icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon,
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildSuggestions(
    List<Map<String, dynamic>> list,
    TextEditingController controller,
    Function(double, double) onSelect,
  ) {
    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      margin: EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: list.length,
        itemBuilder: (context, idx) => ListTile(
          dense: true,
          leading: Icon(Icons.location_city, size: 18),
          title: Text(list[idx]['name'], style: TextStyle(fontSize: 12)),
          onTap: () => setState(() {
            controller.text = list[idx]['name'];
            onSelect(list[idx]['lat'], list[idx]['lng']);
            list.clear();
          }),
        ),
      ),
    );
  }
}
