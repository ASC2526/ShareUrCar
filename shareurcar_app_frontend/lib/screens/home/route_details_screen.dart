import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shareurcar_app_frontend/screens/payments/payments_screen.dart';
import '../../widgets/preferences_card.dart';

import '../../services/api_service.dart';

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
  bool pricesLoaded = false;

  bool isSeries = false;
  int seriesCount = 1;
  List<dynamic> seriesRoutes = [];

  @override
  void initState() {
    super.initState();
    cargarPrecios();
    cargarSerie();
  }

  int get _miId => int.parse(
    (widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'])
        .toString(),
  );

  int? get _routeId {
    final raw =
        widget.ruta['idRoute'] ?? widget.ruta['id_route'] ?? widget.ruta['id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  Future<void> cargarSerie() async {
    try {
      final rid = _routeId;
      if (rid == null) return;
      final info = await ApiService.getSeriesInfo(rid);
      final routes = await ApiService.getSeriesRoutes(rid);
      if (mounted) {
        setState(() {
          isSeries = info['isSeries'] == true;
          seriesCount = (info['totalRoutes'] ?? 1) is int
              ? info['totalRoutes']
              : int.tryParse(info['totalRoutes'].toString()) ?? 1;
          seriesRoutes = routes;
        });
      }
    } catch (e) {
      debugPrint("Error cargando serie: $e");
    }
  }

  Future<void> cargarPrecios() async {
    try {
      final rid = _routeId;
      if (rid == null) return;
      final ida = await ApiService.calculateRoutePrice(rid, _miId, false);
      if (mounted) {
        setState(() {
          oneWayPrice = ida;
          pricesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error cargando precio: $e");
    }
  }

  void unirseARuta(bool rt) async {
    setState(() => isLoading = true);
    try {
      final rid = _routeId;
      if (rid == null) throw Exception("No se encontró el ID de la ruta.");
      await ApiService.joinRoute(rid, _miId, rt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Te has unido a la ruta con éxito!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _mostrarErrorSaldo(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void unirseASerie(bool rt) async {
    setState(() => isLoading = true);
    try {
      final rid = _routeId;
      if (rid == null) throw Exception("No se encontró el ID de la ruta.");
      final result = await ApiService.joinSeries(rid, _miId, rt);
      if (!mounted) return;
      final joined = result['joined'] ?? 0;
      final total = result['totalAmount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Te has unido a $joined viaje(s) · Total retenido: $total €",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _mostrarErrorSaldo(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _mostrarErrorSaldo(String error) {
    final esSaldo = error.toLowerCase().contains("saldo");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              esSaldo
                  ? Icons.account_balance_wallet_outlined
                  : Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(esSaldo ? "Saldo insuficiente" : "No se pudo unir"),
            ),
          ],
        ),
        content: Text(
          esSaldo
              ? "No tienes saldo suficiente. ¿Quieres añadir saldo ahora?"
              : error.replaceAll("Exception: ", ""),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          if (esSaldo)
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
                backgroundColor: const Color(0xFF5F2C82),
              ),
              child: const Text(
                "Gestionar saldo",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // unirse con confirmación
  void _showJoinModal() {
    bool localRoundTrip = false;
    bool localJoinSeries = false;

    final bool allowRoundTrip =
        widget.ruta['allowRoundTrip'] == true ||
        widget.ruta['allow_round_trip'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final precioBase = localRoundTrip ? oneWayPrice * 1.9 : oneWayPrice;
            final precioMostrado = localJoinSeries
                ? precioBase * seriesCount
                : precioBase;

            return Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
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

                    const SizedBox(height: 25),

                    const Text(
                      "Selecciona tu viaje",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // opciones ida / ida+vuelta
                    if (!allowRoundTrip)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 10),
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
                        activeColor: const Color(0xFF5F2C82),
                        title: const Text("Solo ida"),
                        subtitle: Text(
                          "${oneWayPrice.toStringAsFixed(2)} € por viaje",
                        ),
                        onChanged: (v) =>
                            setModalState(() => localRoundTrip = v!),
                      ),
                      RadioListTile(
                        value: true,
                        groupValue: localRoundTrip,
                        activeColor: const Color(0xFF5F2C82),
                        title: const Text("Ida y vuelta"),
                        subtitle: Text(
                          "${(oneWayPrice * 1.9).toStringAsFixed(2)} € por viaje",
                        ),
                        onChanged: (v) =>
                            setModalState(() => localRoundTrip = v!),
                      ),
                    ],

                    // O
                    //opción de unirse a toda la serie
                    if (isSeries) ...[
                      const Divider(height: 30),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          value: localJoinSeries,
                          activeThumbColor: const Color(0xFF5F2C82),
                          title: const Text(
                            "Unirme a toda la serie",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Este conductor tiene $seriesCount viajes. "
                            "Te unes a todos los que tengan plaza.",
                            style: const TextStyle(fontSize: 12),
                          ),
                          onChanged: (v) =>
                              setModalState(() => localJoinSeries = v),
                        ),
                      ),

                      // lista de fechas de la serie cuando se activa
                      if (localJoinSeries && seriesRoutes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Viajes incluidos:",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...seriesRoutes.map((r) {
                                final fecha = _formatearFecha(
                                  r['travel_date']?.toString(),
                                );
                                final hora = _formatearHora(
                                  r['departure_time']?.toString(),
                                );
                                final plazas = r['available_seats'] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: Color(0xFF5F2C82),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "$fecha · $hora",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        "$plazas plazas",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 20),

                    // Resumen precio
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Text(
                            localJoinSeries
                                ? "Total estimado (toda la serie)"
                                : "Precio estimado",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${precioMostrado.toStringAsFixed(2)} €",
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5F2C82),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localJoinSeries
                                ? "Se retiene el total ahora; se ajusta al confirmar cada viaje"
                                : "Incluye gastos compartidos y comisión",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // popup al confirmar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final rt = localRoundTrip;
                          final joinSerie = localJoinSeries;
                          Navigator.pop(ctx);
                          _mostrarConfirmacion(precioMostrado, joinSerie, rt);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F2C82),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Continuar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // popup de confirmación antes de cobrar
  void _mostrarConfirmacion(double precio, bool joinSerie, bool rt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.payments_outlined, color: Color(0xFF5F2C82)),
            SizedBox(width: 10),
            Text("Confirmar reserva"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              joinSerie
                  ? "Vas a unirte a toda la serie ($seriesCount viajes)."
                  : "Vas a unirte a este viaje.",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "Total a retener",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${precio.toStringAsFixed(2)} €",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F2C82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Este importe se retendrá de tu saldo y se ajustará al confirmar el viaje.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (joinSerie) {
                unirseASerie(rt);
              } else {
                unirseARuta(rt);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F2C82),
            ),
            child: const Text(
              "Confirmar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _limpiarDireccion(String dir) =>
      dir.replaceAll(", Alicante", "").trim();

  String _formatearHora(String? hora) {
    if (hora == null) return "--:--";
    return hora.length >= 5 ? hora.substring(0, 5) : hora;
  }

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "";
    try {
      final fecha = DateTime.parse(fechaIso);
      const dias = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
      return "${dias[fecha.weekday - 1]} "
          "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}";
    } catch (_) {
      return fechaIso;
    }
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
    final lat =
        widget.ruta['origin_lat'] ?? widget.ruta['originLat'] ?? 38.3452;
    final lng =
        widget.ruta['origin_lng'] ?? widget.ruta['originLng'] ?? -0.4810;
    final currentUserId = _miId;
    final driverId = widget.ruta['idDriver'] ?? widget.ruta['id_driver'];

    final bool rutaFinalizada = widget.ruta['status'] == 'COMPLETED';
    final bool esMiRuta = driverId == currentUserId;
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
        title: const Text(
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
          // Mapa
          SizedBox(
            height: 220,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  lat is num ? lat.toDouble() : 38.3452,
                  lng is num ? lng.toDouble() : -0.4810,
                ),
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
                      point: LatLng(
                        lat is num ? lat.toDouble() : 38.3452,
                        lng is num ? lng.toDouble() : -0.4810,
                      ),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // título + plazas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Información del viaje",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
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

                  if (isSeries) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.repeat, color: Color(0xFF5F2C82)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Viaje recurrente · $seriesCount viajes en esta serie. "
                              "Puedes unirte a todos a la vez.",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F2C82),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Origen y destino
                  Container(
                    padding: const EdgeInsets.all(15),
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
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _limpiarDireccion(
                                  widget.ruta['origin'].toString(),
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Text(
                              _formatearHora(
                                widget.ruta['departure_time']?.toString(),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 9),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 28,
                              width: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _limpiarDireccion(
                                  widget.ruta['destination'].toString(),
                                ),
                                style: const TextStyle(
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
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fecha + frecuencia
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
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
                        const SizedBox(height: 15),
                        Text(
                          "📅 ${_formatearFechaCompleta(widget.ruta['travel_date'])} · "
                          "${_obtenerFechaRelativa(widget.ruta['travel_date'])}",
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.ruta['return_time'] != null
                              ? "🕒 Salida: ${_formatearHora(widget.ruta['departure_time'])} · "
                                    "Vuelta: ${_formatearHora(widget.ruta['return_time'])}"
                              : "🕒 Salida: ${_formatearHora(widget.ruta['departure_time'])}",
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.repeat, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              "Frecuencia: ${widget.ruta['frequency'] ?? 'Puntual'}",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Preferencias
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
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
                        const SizedBox(height: 15),
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
                        PreferenciasCard(ruta: widget.ruta),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Precio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Precio estimado",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          pricesLoaded
                              ? "${oneWayPrice.toStringAsFixed(2)} €"
                              : "Calculando...",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5F2C82),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // Botón principal
                  rutaFinalizada
                      ? _infoBox("Viaje finalizado", Colors.blueGrey)
                      : esMiRuta
                      ? _infoBox("Esta es tu ruta", Colors.grey)
                      : yaUnido
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 10),
                              Text(
                                "Ya estás en esta ruta",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showJoinModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5F2C82),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isSeries
                                  ? "Unirse a la ruta o serie"
                                  : "Unirse a la ruta",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String texto, MaterialColor color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color.shade700,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
