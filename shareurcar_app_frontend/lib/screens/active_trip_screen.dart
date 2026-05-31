import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/group_chat_screen.dart';
import 'package:shareurcar_app_frontend/widgets/preferences_card.dart';
import '../app_theme.dart';
import '../app_utils.dart';
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

  bool _incidenteReportado = false;

  int get _miId => AppUtils.userId(widget.user);

  int? get _routeId => AppUtils.routeId(widget.ruta);

  bool get _esConductor {
    final driverId = widget.ruta['idDriver'] ?? widget.ruta['id_driver'];
    return driverId == _miId;
  }

  bool get _rutaFinalizada => widget.ruta['status'] == 'COMPLETED';

  bool get _rutaCancelada => widget.ruta['status'] == 'CANCELLED';

  bool get _conductorYaConfirmado => widget.ruta['driverConfirmed'] == true;

  // confirmar llegada / viaje completado
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
                    "Cuando todos los participantes confirmen, el pago se procesará."
              : "¿Confirmas que has completado el viaje? "
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

  // reportar incidencia
  void reportarIncidencia() {
    final rid = _routeId;
    if (rid == null) return;
    final ctrl = TextEditingController();

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
                      "Tu incidencia se enviará para revisión. "
                      "La ruta seguirá activa para el resto de participantes.",
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: ctrl,
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
                await ApiService.reportIncident(rid, _miId, ctrl.text.trim());
                if (!mounted) return;
                setState(() {
                  _incidenteReportado = true;
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Incidencia reportada. Tu caso está en revisión.",
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll("Exception: ", "")),
                    backgroundColor: Colors.red,
                  ),
                );
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

  // abandonar ruta siendo pasajero
  void abandonarRuta() async {
    final rid = _routeId;
    if (rid == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Abandonar viaje?"),
        content: const Text(
          "Se te devolverá el saldo retenido. ¿Estás seguro?",
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
    if (ok != true) return;

    setState(() => isLoading = true);
    try {
      await ApiService.leaveRoute(rid, _miId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Has abandonado la ruta"),
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

  // cancelar ruta siendo conductor
  void cancelarRuta() async {
    final rid = _routeId;
    if (rid == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Cancelar ruta completa?"),
        content: const Text(
          "Se avisará a los pasajeros y se devolverán los saldos.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Volver"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Sí, cancelar",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // chat
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kPrimary.withValues(),
                  child: const Icon(Icons.chat, color: kPrimary),
                ),
                title: const Text(
                  "Chat del grupo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Habla con el conductor y pasajeros"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GroupChatScreen(ruta: widget.ruta, user: widget.user),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // origen destino
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
                      Expanded(child: Text(widget.ruta['origin'] ?? '')),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // info del viaje
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
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: kPrimary),
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
                    "📅 ${AppUtils.formatFechaCompleta(widget.ruta['travel_date'])} · "
                    "${AppUtils.fechaRelativa(widget.ruta['travel_date']?.toString())}",
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.ruta['return_time'] != null
                        ? "🕒 Salida: ${AppUtils.formatHora(widget.ruta['departure_time'])} · "
                              "Vuelta: ${AppUtils.formatHora(widget.ruta['return_time'])}"
                        : "🕒 Salida: ${AppUtils.formatHora(widget.ruta['departure_time'])}",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // preferencias
            PreferenciasCard(ruta: widget.ruta),

            const SizedBox(height: 25),

            _buildAcciones(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAcciones() {
    if (_incidenteReportado) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top, color: Colors.orange),
                SizedBox(width: 10),
                Text(
                  "Tu incidencia está en revisión",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _esConductor ? cancelarRuta : abandonarRuta,
              icon: Icon(
                _esConductor ? Icons.delete_forever : Icons.exit_to_app,
                color: Colors.red,
              ),
              label: Text(
                _esConductor ? "Cancelar ruta" : "Abandonar ruta",
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_rutaCancelada) {
      return _infoBox("Ruta cancelada", Colors.red);
    }

    if (_rutaFinalizada) {
      return _infoBox("Viaje finalizado", Colors.blueGrey);
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // botón confirmar
        if (_esConductor && _conductorYaConfirmado)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  "Ya confirmaste el viaje",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          // Conductor sin confirmar o pasajero
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: confirmarLlegada,
              icon: const Icon(Icons.check_circle, color: Colors.white),
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

        // reportar incidencia
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: reportarIncidencia,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
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

        // cancelar conductor / abandonar pasajero
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _esConductor ? cancelarRuta : abandonarRuta,
            icon: Icon(
              _esConductor ? Icons.delete_forever : Icons.exit_to_app,
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
