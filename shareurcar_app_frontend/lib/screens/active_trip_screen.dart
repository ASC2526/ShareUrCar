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

  void abandonarRuta() async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¿Abandonar viaje?"),
        content: Text(
          "Estás a punto de cancelar tu plaza en este viaje. ¿Estás seguro?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
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
      final routeId =
          widget.ruta['id_route'] ??
          widget.ruta['idRoute'] ??
          widget.ruta['id'];
      final userId =
          widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];

      await ApiService.leaveRoute(
        int.parse(routeId.toString()),
        int.parse(userId.toString()),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

  void finalizarRuta() async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¿Finalizar viaje?"),
        content: Text(
          "Al confirmar, el viaje se marcará como terminado. ¿Es correcto?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Volver"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Sí, finalizar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => isLoading = true);
    try {
      final routeId =
          widget.ruta['id_route'] ??
          widget.ruta['idRoute'] ??
          widget.ruta['id'];
      await ApiService.completeRoute(int.parse(routeId.toString()));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Viaje finalizado con éxito"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void cancelarRuta() async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¿Cancelar ruta completa?"),
        content: Text(
          "Eres el conductor. Si cancelas esta ruta, se avisará a los pasajeros. ¿Estás seguro?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Volver"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
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
      final routeId =
          widget.ruta['id_route'] ??
          widget.ruta['idRoute'] ??
          widget.ruta['id'];
      await ApiService.deleteRoute(int.parse(routeId.toString()));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ruta cancelada correctamente"),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cancelar la ruta"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void confirmarLlegada() async {
    final routeId =
        widget.ruta['id_route'] ?? widget.ruta['idRoute'] ?? widget.ruta['id'];
    final userId =
        widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];

    setState(() => isLoading = true);
    try {
      await ApiService.confirmParticipation(
        int.parse(routeId.toString()),
        int.parse(userId.toString()),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Confirmación enviada!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void reportarIncidencia() {
    final TextEditingController incidenciaController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Reportar incidencia"),
        content: TextField(
          controller: incidenciaController,
          decoration: InputDecoration(hintText: "Explica qué ha pasado..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              // await ApiService.reportIncident();
              Navigator.pop(ctx);
            },
            child: Text("Enviar"),
          ),
        ],
      ),
    );
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
    final bool esConductor =
        (widget.ruta['idDriver'] ?? widget.ruta['id_driver']) ==
        (widget.user['idUser'] ?? widget.user['id_user']);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Color.fromRGBO(95, 44, 130, 0.1),
                  child: Icon(Icons.chat, color: Color(0xFF5F2C82)),
                ),
                title: Text(
                  "Chat del grupo",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Habla con el conductor y pasajeros"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupChatScreen(ruta: widget.ruta, user: widget.user),
                    ),
                  );
                },
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            widget.ruta['origin'] ?? '',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 11),
                        child: Container(
                          height: 20,
                          width: 2,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            widget.ruta['destination'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 15),

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

              SizedBox(height: 15),

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
                          SizedBox(width: 10),
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

              Divider(height: 40),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : confirmarLlegada,
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        "confirmar",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : reportarIncidencia,
                      icon: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      label: Text(
                        "incidencia",
                        style: TextStyle(color: Colors.orange),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : (esConductor ? cancelarRuta : abandonarRuta),
                      icon: Icon(
                        esConductor ? Icons.delete_forever : Icons.exit_to_app,
                        color: Colors.red,
                      ),
                      label: Text(
                        esConductor ? "cancelar ruta" : "abandonar ruta",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
