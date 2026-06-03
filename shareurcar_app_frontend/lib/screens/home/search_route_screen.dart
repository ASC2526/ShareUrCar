import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shareurcar_app_frontend/screens/payments/payments_screen.dart';
import 'package:shareurcar_app_frontend/screens/home/route_details_screen.dart';
import '../../app_theme.dart';
import '../../app_utils.dart';
import '../../services/api_service.dart';
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

  final Set<int> _seleccionadas = {};

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  int get _miId => int.parse(
    (widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'])
        .toString(),
  );

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
        final fechaA =
            DateTime.tryParse(a['travel_date']?.toString() ?? '') ??
            DateTime(2100);
        final fechaB =
            DateTime.tryParse(b['travel_date']?.toString() ?? '') ??
            DateTime(2100);
        return fechaA.compareTo(fechaB);
      });

      setState(() {
        rutasEncontradas = resultados
            .where(
              (r) => r['status'] != 'COMPLETED' && r['status'] != 'CANCELLED',
            )
            .toList();
        _seleccionadas.clear();
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

  int? _routeId(dynamic ruta) {
    final raw = ruta['idRoute'] ?? ruta['id_route'] ?? ruta['id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  // selección de tipo de viaje ida/vuelta + confirmación
  Future<void> _mostrarModalMultiJoin(StateSetter setSheetState) async {
    final rutasSelec = rutasEncontradas.where((r) {
      final rid = _routeId(r);
      return rid != null && _seleccionadas.contains(rid);
    }).toList();

    final anyRoundTrip = rutasSelec.any(
      (r) => r['allowRoundTrip'] == true || r['allow_round_trip'] == true,
    );

    bool localRoundTrip = false;

    double calcularTotal(bool roundTrip) {
      double total = 0;
      for (final r in rutasSelec) {
        final precio = (r['priceOneWay'] ?? 0).toDouble();
        final permiteVuelta =
            r['allowRoundTrip'] == true || r['allow_round_trip'] == true;
        // x1.9 si esa ruta permite vuelta
        total += (roundTrip && permiteVuelta) ? precio * 1.9 : precio;
      }
      return total;
    }

    final seleccion = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setD) {
          final total = calcularTotal(localRoundTrip);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text("Unirte a ${_seleccionadas.length} ruta(s)"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...rutasSelec.map((r) {
                    final destino = AppUtils.limpiarDireccion(
                      (r['destination'] ?? '').toString(),
                    );
                    final fecha = AppUtils.fechaRelativa(
                      r['travel_date']?.toString(),
                    );
                    final hora = AppUtils.formatHora(
                      r['departure_time']?.toString(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 7, color: kPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${fecha.isNotEmpty ? '$fecha · ' : ''}$hora · $destino",
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 24),

                  if (!anyRoundTrip)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Estas rutas solo permiten viaje de ida",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    RadioListTile<bool>(
                      value: false,
                      groupValue: localRoundTrip,
                      activeColor: kPrimary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Solo ida"),
                      onChanged: (v) => setD(() => localRoundTrip = v!),
                    ),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: localRoundTrip,
                      activeColor: kPrimary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Ida y vuelta"),
                      subtitle: const Text(
                        "Solo se aplica a las rutas que lo permiten",
                        style: TextStyle(fontSize: 11),
                      ),
                      onChanged: (v) => setD(() => localRoundTrip = v!),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // total estimado que se actualiza al cambiar la opción
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
                          "Total estimado",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${total.toStringAsFixed(2)} €",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "El importe se retiene ahora y se ajusta al confirmar cada viaje.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, {
                  'roundTrip': localRoundTrip,
                  'total': total,
                }),
                child: const Text(
                  "Continuar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (seleccion == null || !mounted) return;
    final roundTrip = seleccion['roundTrip'] as bool;
    final total = seleccion['total'] as double;

    // Confirmación final con el importe
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, color: kPrimary),
            SizedBox(width: 10),
            Expanded(child: Text("Confirmar reserva")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vas a unirte a ${_seleccionadas.length} ruta(s).",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    "Total a retener",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${total.toStringAsFixed(2)} €",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    roundTrip ? "Ida y vuelta (donde aplique)" : "Solo ida",
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Confirmar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await _ejecutarMultiJoin(setSheetState, roundTrip);
  }

  // multi join
  Future<void> _ejecutarMultiJoin(
    StateSetter setSheetState,
    bool roundTrip,
  ) async {
    setSheetState(() => isLoading = true);
    try {
      final result = await ApiService.joinMultipleRoutes(
        _seleccionadas.toList(),
        _miId,
        roundTrip,
      );

      if (!mounted) return;
      Navigator.pop(context);

      final joined = result['joined'] ?? 0;
      final total = result['totalAmount'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Te has unido a $joined ruta(s) · Total retenido: $total €",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setSheetState(() => isLoading = false);

      final msg = e.toString().replaceAll("Exception: ", "");
      final esSaldo = msg.toLowerCase().contains("saldo");

      if (esSaldo) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: Colors.red),
                SizedBox(width: 10),
                Expanded(child: Text("Saldo insuficiente")),
              ],
            ),
            content: const Text(
              "No tienes saldo suficiente. ¿Quieres añadir saldo ahora?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentsScreen(user: widget.user),
                    ),
                  );
                },
                child: const Text(
                  "Gestionar saldo",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarResultadosBottomSheet() {
    String limpiarDireccion(String direccion) {
      return direccion.replaceAll(", Alicante", "").trim();
    }

    String formatearHora(String hora) {
      return hora.length >= 5 ? hora.substring(0, 5) : hora;
    }

    final rutasVisibles = rutasEncontradas
        .where((r) => r['status'] != 'COMPLETED' && r['status'] != 'CANCELLED')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Rutas disponibles (${rutasVisibles.length})",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (_seleccionadas.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              setSheetState(() => _seleccionadas.clear()),
                          child: Text("Quitar selección"),
                        ),
                    ],
                  ),

                  Text(
                    "Marca varias rutas para unirte a todas a la vez (solo ida), o pulsa una para ver detalles.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 15),

                  Expanded(
                    child: rutasVisibles.isEmpty
                        ? Center(
                            child: Text(
                              "No hay rutas cercanas para este trayecto.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: rutasVisibles.length,
                            itemBuilder: (context, index) {
                              final ruta = rutasVisibles[index];
                              final currentUserId = _miId;
                              final driverId =
                                  ruta['idDriver'] ?? ruta['id_driver'];

                              final int? rid = _routeId(ruta);
                              bool esMiRuta = driverId == currentUserId;
                              bool yaUnido = false;

                              if (ruta['passengers'] != null) {
                                yaUnido = (ruta['passengers'] as List).any((p) {
                                  final pid =
                                      p['idUser'] ?? p['id_user'] ?? p['id'];
                                  return pid == currentUserId;
                                });
                              }

                              final bool seleccionable =
                                  !esMiRuta && !yaUnido && rid != null;
                              final bool marcada =
                                  rid != null && _seleccionadas.contains(rid);

                              return Card(
                                elevation: 0,
                                margin: EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: marcada
                                        ? Color(0xFF5F2C82)
                                        : Colors.grey.shade200,
                                    width: marcada ? 2 : 1,
                                  ),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (seleccionable)
                                            Checkbox(
                                              value: marcada,
                                              activeColor: Color(0xFF5F2C82),
                                              onChanged: (val) {
                                                setSheetState(() {
                                                  if (val == true) {
                                                    _seleccionadas.add(rid);
                                                  } else {
                                                    _seleccionadas.remove(rid);
                                                  }
                                                });
                                              },
                                            ),
                                          Expanded(
                                            child: Column(
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 10),

                                      Text(
                                        "${limpiarDireccion(ruta['origin'].toString())} → ${limpiarDireccion(ruta['destination'].toString())}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),

                                      SizedBox(height: 10),

                                      Row(
                                        children: [
                                          if (ruta['pref_no_talk'] == true ||
                                              ruta['pref_no_talk'] == 1)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Text(
                                                "😶",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          if (ruta['pref_luggage'] == true ||
                                              ruta['pref_luggage'] == 1)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Text(
                                                "💼",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          if (ruta['pref_music'] == true ||
                                              ruta['pref_music'] == 1)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Text(
                                                "🎵",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          if (ruta['pref_smoke'] == true ||
                                              ruta['pref_smoke'] == 1)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Text(
                                                "🚬",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                        ],
                                      ),

                                      SizedBox(height: 10),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              final seUnio =
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          RouteDetailsScreen(
                                                            ruta:
                                                                Map<
                                                                  String,
                                                                  dynamic
                                                                >.from(ruta),
                                                            user: widget.user,
                                                          ),
                                                    ),
                                                  );
                                              if (seUnio == true && mounted) {
                                                Navigator.pop(context, true);
                                              }
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                    horizontal: 4.0,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 18,
                                                    color: Color(0xFF5F2C82),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "Ver detalles",
                                                    style: TextStyle(
                                                      color: Color(0xFF5F2C82),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (esMiRuta)
                                            Text(
                                              "Tu ruta",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          else if (yaUnido)
                                            Row(
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

                  if (_seleccionadas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => _mostrarModalMultiJoin(setSheetState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5F2C82),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Unirse a ${_seleccionadas.length} ruta(s)",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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
                initialCenter: LatLng(38.3452, -0.4810),
                initialZoom: 13.0,
                cameraConstraint: CameraConstraint.contain(
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
