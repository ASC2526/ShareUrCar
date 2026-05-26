import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;
  final Map user;

  const RouteDetailsScreen({super.key, required this.ruta, required this.user});

  @override
  _RouteDetailsScreenState createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  bool isLoading = false;

  void unirseARuta() async {
    setState(() => isLoading = true);
    try {
      // buscamos el ID de la ruta en todos los formatos posibles
      var rawRouteId =
          widget.ruta['id_route'] ??
          widget.ruta['idRoute'] ??
          widget.ruta['id'];
      var rawUserId =
          widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];

      if (rawRouteId == null)
        throw Exception(
          "No se ha podido encontrar el ID de la ruta en la base de datos.",
        );
      if (rawUserId == null)
        throw Exception("No se ha podido encontrar el ID de tu usuario.");

      // los convertimos a int
      final int finalRouteId = rawRouteId is int
          ? rawRouteId
          : int.parse(rawRouteId.toString());
      final int finalUserId = rawUserId is int
          ? rawUserId
          : int.parse(rawUserId.toString());

      await ApiService.joinRoute(finalRouteId, finalUserId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Te has unido a la ruta con éxito!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _limpiarDireccion(String dir) =>
      dir.replaceAll(", Alicante", "").trim();
  String _formatearHora(String hora) =>
      hora.length >= 5 ? hora.substring(0, 5) : hora;

  @override
  Widget build(BuildContext context) {
    final lat = widget.ruta['origin_lat'] ?? 38.3452;
    final lng = widget.ruta['origin_lng'] ?? -0.4810;

    final currentUserId =
        widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];
    final driverId = widget.ruta['idDriver'] ?? widget.ruta['id_driver'];

    bool esMiRuta = driverId == currentUserId;
    bool yaUnido = false;

    if (widget.ruta['passengers'] != null) {
      yaUnido = (widget.ruta['passengers'] as List).any((p) {
        final pid = p['idUser'] ?? p['id_user'] ?? p['id'];
        return pid == currentUserId;
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Detalles de la ruta",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // MAPA SUPERIOR
          SizedBox(
            height: 250,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.asc2526.shareurcar',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue.shade600,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // INFORMACIÓN DE LA RUTA
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Información del viaje",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${widget.ruta['available_seats']} plazas libres",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Tarjeta de origen y destino
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.radio_button_checked,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _limpiarDireccion(
                                  widget.ruta['origin'].toString(),
                                ),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            Text(
                              _formatearHora(
                                widget.ruta['departure_time'].toString(),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 9),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 30,
                              width: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _limpiarDireccion(
                                  widget.ruta['destination'].toString(),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              widget.ruta['arrival_time'] != null
                                  ? _formatearHora(
                                      widget.ruta['arrival_time'].toString(),
                                    )
                                  : "--:--",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Frecuencia
                  Row(
                    children: [
                      Icon(Icons.repeat, color: Colors.grey.shade600),
                      SizedBox(width: 10),
                      Text(
                        "Frecuencia: ${widget.ruta['frequency'] ?? 'Puntual'}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),

                  // BOTÓN UNIRSE
                  esMiRuta
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Esta es tu ruta",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : yaUnido
                      ? Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 10),
                              Text(
                                "Ya estás en esta ruta",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: unirseARuta,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5F2C82),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Unirse a la ruta",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}
