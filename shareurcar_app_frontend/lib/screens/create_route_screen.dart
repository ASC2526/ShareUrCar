import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'dart:async';

class CreateRouteScreen extends StatefulWidget {
  final Map user;

  const CreateRouteScreen({super.key, required this.user});

  @override
  _CreateRouteScreenState createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();

  final originController = TextEditingController();
  final destinationController = TextEditingController();
  final pickupController = TextEditingController();
  final colorController = TextEditingController();

  List<Map<String, dynamic>> originSuggestions = [];
  List<Map<String, dynamic>> destinationSuggestions = [];
  List<Map<String, dynamic>> pickupSuggestions = [];

  double? selectedOriginLat;
  double? selectedOriginLng;
  double? selectedDestLat;
  double? selectedDestLng;
  List<String> puntosRecogida = [];

  TimeOfDay horaSalida = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? horaVuelta;
  int plazas = 3;

  String frecuenciaSeleccionada = 'puntual';
  DateTime? fechaPuntual;
  DateTime? fechaInicioSemanal;
  DateTime? fechaFinSemanal;
  List<String> diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  List<String> diasSeleccionados = [];

  // Preferencias
  bool prefSinConversar = false;
  bool prefEquipaje = false;
  bool prefMusica = false;
  bool prefFumar = false;
  bool allowRoundTrip = false;

  bool isLoading = false;
  Timer? _debounce;

  // funciones para hora y fecha
  Future<void> _seleccionarHoraSalida(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: horaSalida,
    );
    if (picked != null && picked != horaSalida) {
      setState(() => horaSalida = picked);
    }
  }

  Future<void> _seleccionarHoraVuelta(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: horaVuelta ?? TimeOfDay(hour: 15, minute: 0),
    );
    if (picked != null) {
      setState(() => horaVuelta = picked);
    }
  }

  Future<void> _seleccionarFechaPuntual(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF5F2C82),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != fechaPuntual) {
      setState(() => fechaPuntual = picked);
    }
  }

  void _addPickupPoint() {
    if (pickupController.text.trim().isNotEmpty) {
      setState(() {
        puntosRecogida.add(pickupController.text.trim());
        pickupController.clear();
        pickupSuggestions = [];
      });
    }
  }

  void submitRoute() async {
    if (!_formKey.currentState!.validate()) return;

    final ahora = DateTime.now();
    final horaActual = TimeOfDay.now();

    if (frecuenciaSeleccionada == 'puntual') {
      if (fechaPuntual == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Debes seleccionar una fecha para tu viaje"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (fechaPuntual!.year == ahora.year &&
          fechaPuntual!.month == ahora.month &&
          fechaPuntual!.day == ahora.day) {
        if (horaSalida.hour < horaActual.hour ||
            (horaSalida.hour == horaActual.hour &&
                horaSalida.minute < horaActual.minute)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("La hora de salida no puede ser en el pasado"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    if (frecuenciaSeleccionada == 'semanal') {
      if (diasSeleccionados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Debes seleccionar al menos un día de la semana"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (fechaInicioSemanal == null || fechaFinSemanal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Debes seleccionar fecha de inicio y fin"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (fechaFinSemanal!.isBefore(fechaInicioSemanal!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("La fecha fin no puede ser anterior a la de inicio"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (allowRoundTrip && horaVuelta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Debes indicar a qué hora es la vuelta"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedOriginLat == null || selectedDestLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selecciona las direcciones de la lista"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    if (selectedOriginLat == null) {
      final fallbackOrigen = await ApiService.getAddressSuggestions(
        originController.text,
      );
      if (fallbackOrigen.isNotEmpty) {
        selectedOriginLat = fallbackOrigen[0]['lat'];
        selectedOriginLng = fallbackOrigen[0]['lng'];
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No se encuentra el Origen exacto."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (selectedDestLat == null) {
      final fallbackDestino = await ApiService.getAddressSuggestions(
        destinationController.text,
      );
      if (fallbackDestino.isNotEmpty) {
        selectedDestLat = fallbackDestino[0]['lat'];
        selectedDestLng = fallbackDestino[0]['lng'];
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No se encuentra el Destino exacto."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    try {
      final String horaFormateada =
          "${horaSalida.hour.toString().padLeft(2, '0')}:${horaSalida.minute.toString().padLeft(2, '0')}:00";
      final String horaVueltaFormateada = allowRoundTrip && horaVuelta != null
          ? "${horaVuelta!.hour.toString().padLeft(2, '0')}:${horaVuelta!.minute.toString().padLeft(2, '0')}:00"
          : "";

      String daysOfWeek = "";
      String travelDate = "";
      String startDate = "";
      String endDate = "";

      if (frecuenciaSeleccionada == 'puntual') {
        travelDate = DateFormat('yyyy-MM-dd').format(fechaPuntual!);
        daysOfWeek = "Puntual";
      } else {
        daysOfWeek = diasSeleccionados.join(",");
        startDate = DateFormat('yyyy-MM-dd').format(fechaInicioSemanal!);
        endDate = DateFormat('yyyy-MM-dd').format(fechaFinSemanal!);
        travelDate = startDate;
      }

      await ApiService.createRoute({
        "idDriver": widget.user['idUser'],
        "origin": originController.text.trim(),
        "originLat": selectedOriginLat,
        "originLng": selectedOriginLng,
        "destination": destinationController.text.trim(),
        "destinationLat": selectedDestLat,
        "destinationLng": selectedDestLng,
        "departure_time": horaFormateada,
        "frequency": frecuenciaSeleccionada,
        "days_of_week": daysOfWeek,
        "travel_date": travelDate,
        "start_date": startDate.isNotEmpty ? startDate : null,
        "end_date": endDate.isNotEmpty ? endDate : null,
        "available_seats": plazas,
        "allowRoundTrip": allowRoundTrip,
        "return_time": allowRoundTrip ? horaVueltaFormateada : null,
        "pref_no_talk": prefSinConversar,
        "pref_luggage": prefEquipaje,
        "pref_music": prefMusica,
        "pref_smoke": prefFumar,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Ruta creada con éxito!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      String error = e.toString().replaceAll("Exception: ", "");

      if (error.contains("coche") ||
          error.contains("conductor") ||
          error.contains("vehículo")) {
        _showRegisterCarDialog();
        return;
      }

      if (error.contains("409")) {
        error = "Ya existe un vehículo con esa matrícula";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // diálogo registrar coche
  void _showRegisterCarDialog() {
    final plateController = TextEditingController();
    final modelController = TextEditingController();
    final carSeatsController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Color(0xFF5F2C82)),
            SizedBox(width: 10),
            Text(
              "Registra tu coche",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Para publicar una ruta, primero debes registrar tu vehículo.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: plateController,
              decoration: _inputDeco("Matrícula (Ej: 1234ABC)", null),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: modelController,
              decoration: _inputDeco("Modelo (Ej: Dacia Sandero)", null),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: carSeatsController,
              decoration: _inputDeco("Plazas máximas( Contándote a ti)", null),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: colorController,
              decoration: _inputDeco("Color (Ej: Rojo)", null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF49A09D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                await ApiService.registerDriver({
                  "carPlate": plateController.text.trim(),
                  "idDriver": widget.user['idUser'],
                  "carModel": modelController.text.trim(),
                  "maxSeats": int.parse(carSeatsController.text.trim()),
                  "carColor": colorController.text.trim(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "¡Coche registrado! Dale a Publicar Ruta otra vez.",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (ex) {
                if (!mounted) return;

                String error = ex.toString().replaceAll("Exception: ", "");

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              }
            },
            child: Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Publicar un viaje",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // trayecto
              _buildContainer(
                title: "Recorrido",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Origen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: originController,
                      decoration: _inputDeco(
                        "¿Desde dónde sales?",
                        Icon(
                          Icons.radio_button_checked,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      onChanged: (val) async {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          Duration(milliseconds: 600),
                          () async {
                            final sug = await ApiService.getAddressSuggestions(
                              val,
                            );
                            if (mounted) {
                              setState(() => originSuggestions = sug);
                            }
                          },
                        );
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
                    SizedBox(height: 15),
                    Text(
                      "Destino",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: destinationController,
                      decoration: _inputDeco(
                        "¿A dónde vas?",
                        Icon(Icons.location_on, color: Colors.red),
                      ),
                      validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      onChanged: (val) async {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          Duration(milliseconds: 600),
                          () async {
                            final sug = await ApiService.getAddressSuggestions(
                              val,
                            );
                            if (mounted) {
                              setState(() => destinationSuggestions = sug);
                            }
                          },
                        );
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
                  ],
                ),
              ),

              SizedBox(height: 15),

              // frecuencia y calendario
              _buildContainer(
                title: "¿Cuándo viajas?",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => frecuenciaSeleccionada = 'puntual',
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: frecuenciaSeleccionada == 'puntual'
                                      ? Color(0xFF49A09D)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "Un día concreto",
                                    style: TextStyle(
                                      color: frecuenciaSeleccionada == 'puntual'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => frecuenciaSeleccionada = 'semanal',
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: frecuenciaSeleccionada == 'semanal'
                                      ? Color(0xFF49A09D)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "Viaje recurrente",
                                    style: TextStyle(
                                      color: frecuenciaSeleccionada == 'semanal'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),

                    if (frecuenciaSeleccionada == 'puntual')
                      InkWell(
                        onTap: () => _seleccionarFechaPuntual(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: Color(0xFF5F2C82),
                              ),
                              SizedBox(width: 15),
                              Text(
                                fechaPuntual == null
                                    ? "Selecciona la fecha"
                                    : DateFormat(
                                        'dd / MM / yyyy',
                                      ).format(fechaPuntual!),
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selecciona los días:",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: diasSemana.map((dia) {
                              final bool seleccionado = diasSeleccionados
                                  .contains(dia);
                              return FilterChip(
                                label: Text(
                                  dia,
                                  style: TextStyle(
                                    color: seleccionado
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: seleccionado,
                                selectedColor: Color(0xFF5F2C82),
                                backgroundColor: Colors.grey.shade200,
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      diasSeleccionados.add(dia);
                                    } else {
                                      diasSeleccionados.remove(dia);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            Duration(days: 90),
                                          ),
                                        );
                                    if (picked != null) {
                                      setState(
                                        () => fechaInicioSemanal = picked,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Inicia",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          fechaInicioSemanal == null
                                              ? "Seleccionar"
                                              : DateFormat(
                                                  'dd/MM/yy',
                                                ).format(fechaInicioSemanal!),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final DateTime?
                                    picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          fechaInicioSemanal ?? DateTime.now(),
                                      firstDate:
                                          fechaInicioSemanal ?? DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        Duration(days: 90),
                                      ),
                                    );
                                    if (picked != null) {
                                      setState(() => fechaFinSemanal = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Termina",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          fechaFinSemanal == null
                                              ? "Seleccionar"
                                              : DateFormat(
                                                  'dd/MM/yy',
                                                ).format(fechaFinSemanal!),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              SizedBox(height: 15),

              // detalles
              _buildContainer(
                title: "Detalles",
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarHoraSalida(context),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hora de salida",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Color(0xFF49A09D),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        horaSalida.format(context),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 4,
                                  ),
                                  child: Text(
                                    "Asientos libres",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline),
                                      onPressed: plazas > 1
                                          ? () => setState(() => plazas--)
                                          : null,
                                      color: Colors.red.shade300,
                                    ),
                                    Text(
                                      "$plazas",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline),
                                      onPressed: plazas < 6
                                          ? () => setState(() => plazas++)
                                          : null,
                                      color: Colors.green.shade400,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 15),

                    CheckboxListTile(
                      value: allowRoundTrip,
                      onChanged: (value) {
                        setState(() {
                          allowRoundTrip = value!;
                          if (!allowRoundTrip) horaVuelta = null;
                        });
                      },
                      activeColor: Color(0xFF5F2C82),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Permitir ida y vuelta",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Los pasajeros podrán reservar regreso",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (allowRoundTrip)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: InkWell(
                          onTap: () => _seleccionarHoraVuelta(context),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings_backup_restore,
                                  color: Color(0xFF5F2C82),
                                ),
                                SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hora de vuelta",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      horaVuelta == null
                                          ? "Seleccionar hora"
                                          : horaVuelta!.format(context),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 15),

              // puntos recogida
              _buildContainer(
                title: "Puntos de recogida (opcional)",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: pickupController,
                            decoration: _inputDeco(
                              "Añadir dirección...",
                              Icon(Icons.add_location_alt, size: 18),
                            ),
                            onChanged: (val) {
                              if (_debounce?.isActive ?? false) {
                                _debounce!.cancel();
                              }
                              _debounce = Timer(
                                Duration(milliseconds: 600),
                                () async {
                                  final sug =
                                      await ApiService.getAddressSuggestions(
                                        val,
                                      );
                                  if (mounted) {
                                    setState(() => pickupSuggestions = sug);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF5F2C82),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: _addPickupPoint,
                          ),
                        ),
                      ],
                    ),
                    if (pickupSuggestions.isNotEmpty)
                      _buildSuggestions(
                        pickupSuggestions,
                        pickupController,
                        (lat, lng) {},
                      ),

                    if (puntosRecogida.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          children: puntosRecogida
                              .map(
                                (punto) => Chip(
                                  label: Text(
                                    punto,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: Icon(Icons.cancel, size: 18),
                                  onDeleted: () => setState(
                                    () => puntosRecogida.remove(punto),
                                  ),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),

              // preferencias
              _buildContainer(
                title: "Preferencias del viaje",
                child: Column(
                  children: [
                    _buildCheckboxRow(
                      "😶",
                      "Viaje sin conversar",
                      prefSinConversar,
                      (val) => setState(() => prefSinConversar = val!),
                    ),
                    _buildCheckboxRow(
                      "💼",
                      "Equipaje permitido",
                      prefEquipaje,
                      (val) => setState(() => prefEquipaje = val!),
                    ),
                    _buildCheckboxRow(
                      "🎵",
                      "Música durante el viaje",
                      prefMusica,
                      (val) => setState(() => prefMusica = val!),
                    ),
                    _buildCheckboxRow(
                      "🚬",
                      "Fumar permitido",
                      prefFumar,
                      (val) => setState(() => prefFumar = val!),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // información
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF90CAF9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ℹ️", style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Recuerda que ShareUrCar es una plataforma para compartir gastos de viaje, no para obtener beneficios económicos. Los precios recomendados se calculan en base al trayecto.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0D47A1),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // botón publicar
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5F2C82),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Publicar Ruta",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // widgets reutilizables
  Widget _buildContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F2C82),
            ),
          ),
          SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, Icon? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: icon,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF5F2C82)),
      ),
    );
  }

  Widget _buildSuggestions(
    List<Map<String, dynamic>> list,
    TextEditingController controller,
    Function(double, double) onSelect,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
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

  Widget _buildCheckboxRow(
    String emoji,
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 14)),
            ],
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF5F2C82),
          ),
        ],
      ),
    );
  }
}
