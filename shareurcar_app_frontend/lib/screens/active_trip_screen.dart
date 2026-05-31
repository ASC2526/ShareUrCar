import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/group_chat_screen.dart';
import '../services/api_service.dart';

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;
  final Map user;

  const ActiveTripScreen({super.key, required this.ruta, required this.user});

  @override
  _ActiveTripScreenState createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  bool isLoading = false;

  int get _miId => int.parse(
    (widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'])
        .toString(),
  );

  int? get _routeId {
    final raw =
        widget.ruta['id_route'] ?? widget.ruta['idRoute'] ?? widget.ruta['id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  bool get _esConductor {
    final driverId = widget.ruta['idDriver'] ?? widget.ruta['id_driver'];
    return driverId == _miId;
  }

  bool get _rutaFinalizada =>
      widget.ruta['status'] == 'COMPLETED' ||
      widget.ruta['status'] == 'CANCELLED';

  void confirmarLlegada() async {
    final rid = _routeId;
    if (rid == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 10),
            Expanded(child: Text("Confirmar viaje")),
          ],
        ),
        content: Text(
          _esConductor
              ? "¿Confirmas que has realizado el viaje correctamente? "
                    "Cuando todos los participantes confirmen, el pago se procesará automáticamente."
              : "¿Confirmas que has completado el viaje correctamente? "
                    "El pago se procesará cuando todos confirmen.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Sí, confirmar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => isLoading = true);
    try {
      await ApiService.confirmParticipation(rid, _miId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Confirmación enviada!"),
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

  void reportarIncidencia() {
    final rid = _routeId;
    if (rid == null) return;

    final TextEditingController incidenciaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text("Reportar incidencia")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Al enviar la incidencia, la ruta se cancelará "
                      "y se devolverán los saldos a todos los participantes.",
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: incidenciaController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Explica brevemente qué ha pasado...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoading = true);
              try {
                await ApiService.reportIncident(
                  rid,
                  _miId,
                  incidenciaController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Incidencia reportada. La ruta ha sido cancelada "
                      "y se han devuelto los saldos.",
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
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
            },
            child: const Text(
              "Enviar incidencia",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void abandonarRuta() async {
    final rid = _routeId;
    if (rid == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Abandonar viaje?"),
        content: const Text(
          "Estás a punto de cancelar tu plaza en este viaje. "
          "Se te devolverá el saldo retenido.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Sí, abandonar",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => isLoading = true);
    try {
      await ApiService.leaveRoute(rid, _miId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Has abandonado la ruta correctamente"),
          backgroundColor: Colors.orange,
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

  void cancelarRuta() async {
    final rid = _routeId;
    if (rid == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Cancelar ruta completa?"),
        content: const Text(
          "Eres el conductor. Si cancelas esta ruta, se avisará a los "
          "pasajeros y se devolverán los saldos. ¿Estás seguro?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Volver"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Sí, cancelar ruta",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => isLoading = true);
    try {
      await ApiService.deleteRoute(rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ruta cancelada correctamente"),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al cancelar la ruta"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatearHora(String hora) {
    try {
      final partes = hora.split(":");
      return "${partes[0]}:${partes[1]}";
    } catch (_) {
      return hora;
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Gestión del Viaje",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF5F2C82).withOpacity(0.1),
                    child: const Icon(Icons.chat, color: Color(0xFF5F2C82)),
                  ),
                  title: const Text(
                    "Chat del grupo",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Habla con el conductor y pasajeros"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(
                          ruta: widget.ruta,
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            widget.ruta['origin'] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: Container(
                          height: 20,
                          width: 2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            widget.ruta['destination'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

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
                            fontSize: 16,
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
                    const SizedBox(height: 8),
                    Text(
                      widget.ruta['return_time'] != null
                          ? "🕒 Salida: ${_formatearHora(widget.ruta['departure_time'])} · "
                                "Vuelta: ${_formatearHora(widget.ruta['return_time'])}"
                          : "🕒 Salida: ${_formatearHora(widget.ruta['departure_time'])}",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

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
                            fontSize: 16,
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

              const SizedBox(height: 25),

              if (_rutaFinalizada)
                _infoBox(
                  widget.ruta['status'] == 'CANCELLED'
                      ? "Ruta cancelada"
                      : "Viaje finalizado",
                  widget.ruta['status'] == 'CANCELLED'
                      ? Colors.red
                      : Colors.blueGrey,
                )
              else if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    // Confirmar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: confirmarLlegada,
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: Text(
                          _esConductor
                              ? "Confirmar viaje realizado"
                              : "Confirmar llegada",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reportar incidencia
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: reportarIncidencia,
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          "Reportar incidencia",
                          style: TextStyle(color: Colors.orange),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancelar / Abandonar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _esConductor ? cancelarRuta : abandonarRuta,
                        icon: Icon(
                          _esConductor
                              ? Icons.delete_forever
                              : Icons.exit_to_app,
                          color: Colors.red,
                        ),
                        label: Text(
                          _esConductor ? "Cancelar ruta" : "Abandonar ruta",
                          style: const TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String texto, MaterialColor color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
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
