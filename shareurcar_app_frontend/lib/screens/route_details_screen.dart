import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shareurcar_app_frontend/screens/payments_screen.dart';
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
  bool roundTrip = false;

  double oneWayPrice = 0;
  double roundTripPrice = 0;

  bool pricesLoaded = false;

  @override
  void initState() {
    super.initState();
    cargarPrecios();
  }

  void unirseARuta() async {
    setState(() => isLoading = true);

    try {
      var rawRouteId =
          widget.ruta['id_route'] ??
          widget.ruta['idRoute'] ??
          widget.ruta['id'];

      var rawUserId =
          widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];

      if (rawRouteId == null) {
        throw Exception(
          "No se ha podido encontrar el ID de la ruta en la base de datos.",
        );
      }

      if (rawUserId == null) {
        throw Exception("No se ha podido encontrar el ID de tu usuario.");
      }

      final int finalRouteId = rawRouteId is int
          ? rawRouteId
          : int.parse(rawRouteId.toString());

      final int finalUserId = rawUserId is int
          ? rawUserId
          : int.parse(rawUserId.toString());

      await ApiService.joinRoute(finalRouteId, finalUserId, roundTrip);

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

      showDialog(
        context: context,

        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.red),

              SizedBox(width: 10),

              Text("Saldo insuficiente"),
            ],
          ),

          content: Text(
            "No puedes unirte a esta ruta porque tu saldo disponible es insuficiente.",
            style: TextStyle(fontSize: 15),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: Text("Cancelar"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentsScreen(user: widget.user),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5F2C82),
              ),

              child: Text(
                "Gestionar saldo",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _limpiarDireccion(String dir) =>
      dir.replaceAll(", Alicante", "").trim();

  String _formatearHora(String hora) =>
      hora.length >= 5 ? hora.substring(0, 5) : hora;

  Future<void> cargarPrecios() async {
    try {
      final routeId =
          widget.ruta['idRoute'] ??
          widget.ruta['id_route'] ??
          widget.ruta['id'];

      final userId =
          widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];

      final ida = await ApiService.calculateRoutePrice(routeId, userId, false);

      final idaVuelta = await ApiService.calculateRoutePrice(
        routeId,
        userId,
        true,
      );

      if (mounted) {
        setState(() {
          oneWayPrice = ida;

          roundTripPrice = idaVuelta;

          pricesLoaded = true;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _showJoinModal() {
    bool localRoundTrip = false;

    bool allowRoundTrip =
        widget.ruta['allowRoundTrip'] == true ||
        widget.ruta['allow_round_trip'] == true;

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    Text(
                      "Selecciona tu viaje",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 20),

                    if (!allowRoundTrip)
                      Container(
                        width: double.infinity,

                        padding: EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),

                            SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                "Esta ruta solo permite viaje de ida",
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (allowRoundTrip) ...[
                      RadioListTile(
                        value: false,

                        groupValue: localRoundTrip,

                        activeColor: Color(0xFF5F2C82),

                        title: Text("Solo ida"),

                        subtitle: Text(
                          "${oneWayPrice.toStringAsFixed(2)} € · Reserva únicamente el trayecto de ida",
                        ),

                        onChanged: (value) {
                          setModalState(() {
                            localRoundTrip = value!;
                          });
                        },
                      ),

                      RadioListTile(
                        value: true,

                        groupValue: localRoundTrip,

                        activeColor: Color(0xFF5F2C82),

                        title: Text("Ida y vuelta"),

                        subtitle: Text(
                          "${(oneWayPrice * 1.9).toStringAsFixed(2)} € · Incluye trayecto de regreso",
                        ),

                        onChanged: (value) {
                          setModalState(() {
                            localRoundTrip = value!;
                          });
                        },
                      ),
                    ],

                    SizedBox(height: 20),

                    Container(
                      width: double.infinity,

                      padding: EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: Column(
                        children: [
                          Text(
                            "Precio estimado",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            "${(localRoundTrip ? oneWayPrice * 1.9 : oneWayPrice).toStringAsFixed(2)} €",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5F2C82),
                            ),
                          ),

                          SizedBox(height: 8),

                          Text(
                            "Incluye gastos compartidos y comisión de servicio",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: () {
                          roundTrip = localRoundTrip;

                          Navigator.pop(context);

                          unirseARuta();
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5F2C82),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: Text(
                          "Confirmar reserva",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatearFechaCompleta(String? fechaIso) {
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
      return fechaIso;
    }
  }

  String _obtenerFechaRelativa(String? fechaIso) {
    if (fechaIso == null) return "";

    try {
      final fecha = DateTime.parse(fechaIso);
      final hoy = DateTime.now();

      final diff = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
      ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;

      if (diff == 0) return "Hoy";
      if (diff == 1) return "Mañana";

      return "En $diff días";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.ruta['origin_lat'] ?? 38.3452;
    final lng = widget.ruta['origin_lng'] ?? -0.4810;
    final currentUserId =
        widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];
    final driverId = widget.ruta['idDriver'] ?? widget.ruta['id_driver'];

    bool rutaFinalizada = widget.ruta['status'] == 'COMPLETED';
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
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF5F2C82)),
                            SizedBox(width: 10),
                            Text(
                              "Información del viaje",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        Text(
                          "📅 ${_formatearFechaCompleta(widget.ruta['travel_date'])} · "
                          "${_obtenerFechaRelativa(widget.ruta['travel_date'])}",
                        ),

                        SizedBox(height: 10),

                        Text(
                          widget.ruta['return_time'] != null
                              ? "🕒 Salida: ${_formatearHora(widget.ruta['departure_time'])} · "
                                    "Vuelta: ${_formatearHora(widget.ruta['return_time'])}"
                              : "🕒 Salida: ${_formatearHora(widget.ruta['departure_time'])}",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune, color: Color(0xFF5F2C82)),
                            SizedBox(width: 10),
                            Text(
                              "Preferencias del conductor",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: (widget.ruta['allowRoundTrip'] ?? false)
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (widget.ruta['allowRoundTrip'] ?? false)
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                (widget.ruta['allowRoundTrip'] ?? false)
                                    ? Icons.swap_horiz
                                    : Icons.block,
                                color: (widget.ruta['allowRoundTrip'] ?? false)
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                (widget.ruta['allowRoundTrip'] ?? false)
                                    ? "Ruta con ida y vuelta"
                                    : "Solo viaje de ida",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      (widget.ruta['allowRoundTrip'] ?? false)
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CheckboxListTile(
                          value:
                              widget.ruta['prefNoTalk'] ??
                              widget.ruta['pref_no_talk'] ??
                              false,
                          onChanged: null,
                          title: const Text("😶 Viaje sin conversar"),
                        ),

                        CheckboxListTile(
                          value:
                              widget.ruta['prefLuggage'] ??
                              widget.ruta['pref_luggage'] ??
                              false,
                          onChanged: null,
                          title: const Text("💼 Equipaje permitido"),
                        ),

                        CheckboxListTile(
                          value:
                              widget.ruta['prefMusic'] ??
                              widget.ruta['pref_music'] ??
                              false,
                          onChanged: null,
                          title: const Text("🎵 Música durante el viaje"),
                        ),

                        CheckboxListTile(
                          value:
                              widget.ruta['prefSmoke'] ??
                              widget.ruta['pref_smoke'] ??
                              false,
                          onChanged: null,
                          title: const Text("🚬 Fumar permitido"),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),

                  Container(
                    width: double.infinity,

                    padding: EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              color: Color(0xFF5F2C82),
                            ),

                            SizedBox(width: 10),

                            Text(
                              "Información del viaje",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              "Precio estimado",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            Text(
                              pricesLoaded
                                  ? "${oneWayPrice.toStringAsFixed(2)} €"
                                  : "Calculando...",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5F2C82),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 18),

                        Row(
                          children: [
                            Checkbox(
                              value:
                                  widget.ruta['allowRoundTrip'] == true ||
                                  widget.ruta['allow_round_trip'] == true,

                              onChanged: null,

                              activeColor: Color(0xFF5F2C82),
                            ),

                            Expanded(
                              child: Text(
                                "Permite ida y vuelta",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              color: Colors.grey.shade600,
                            ),

                            SizedBox(width: 10),

                            Text(
                              "Viaje compartido",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  rutaFinalizada
                      ? Container(
                          width: double.infinity,

                          padding: EdgeInsets.symmetric(vertical: 16),

                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Text(
                            "Viaje finalizado",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : esMiRuta
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
                            onPressed: () {
                              _showJoinModal();
                            },

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
