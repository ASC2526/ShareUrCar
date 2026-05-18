import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final seatsController = TextEditingController();
  final pickupController = TextEditingController();

  // Autocompletado
  List<String> originSuggestions = [];
  List<String> destinationSuggestions = [];
  List<String> pickupSuggestions = [];

  // Puntos de recogida (Lista dinámica)
  List<String> puntosRecogida = [];

  // Adaptado a tu BBDD (Puedes añadir más si lo cambias en el back)
  String frecuenciaSeleccionada = 'Puntual';
  final List<String> opcionesFrecuencia = ['Puntual', 'Diario', 'Semanal', 'Fines de semana'];

  // Preferencias con Checkbox
  bool prefSinConversar = false;
  bool prefEquipaje = false;
  bool prefMusica = false;
  bool prefFumar = false;

  bool isLoading = false;

  void submitRoute() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      List<String> prefsActivas = [];
      if (prefSinConversar) prefsActivas.add("Sin conversar");
      if (prefEquipaje) prefsActivas.add("Equipaje permitido");
      if (prefMusica) prefsActivas.add("Música");
      if (prefFumar) prefsActivas.add("Fumar permitido");

      // Mandamos la petición al backend de Spring Boot
      await ApiService.createRoute({
        "idDriver": widget.user['idUser'],
        "origin": originController.text.trim(),
        "destination": destinationController.text.trim(),
        "departure_time": "${timeController.text.trim()}:00",
        "frequency": frecuenciaSeleccionada,
        "available_seats": int.parse(seatsController.text.trim()),
        // para guardar la lista de puntosRecogida o prefsActivas, 
        // haay que añadir esos campos a la entidad Route en Spring Boot.
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("¡Ruta creada con éxito!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains("coche") || e.toString().contains("conductor")) {
        _showRegisterCarDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- POPUP PARA REGISTRAR COCHE ---
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
            Text("Registra tu coche", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Para publicar una ruta, primero debes registrar tu vehículo en el sistema.",
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
              decoration: _inputDeco("Modelo (Ej: Seat Ibiza)", null),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: carSeatsController,
              decoration: _inputDeco("Plazas máximas", null),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF49A09D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await ApiService.registerDriver({
                  "carPlate": plateController.text.trim(),
                  "idDriver": widget.user['idUser'], 
                  "carModel": modelController.text.trim(),
                  "maxSeats": int.parse(carSeatsController.text.trim()),
                });

                if (!mounted) return;
                Navigator.pop(context); // Cerramos el popup

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("¡Coche registrado! Dale a Publicar Ruta otra vez."), backgroundColor: Colors.green),
                );
              } catch (ex) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ex.toString()), backgroundColor: Colors.red),
                );
              }
            },
            child: Text("Guardar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- MÉTODOS FECHA/HORA ---
  Future<void> _seleccionarFecha() async {
    DateTime? fechaElegida = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030),
    );
    if (fechaElegida != null) {
      setState(() {
        dateController.text = "${fechaElegida.day.toString().padLeft(2, '0')}/${fechaElegida.month.toString().padLeft(2, '0')}/${fechaElegida.year}";
      });
    }
  }

  Future<void> _seleccionarHora() async {
    TimeOfDay? horaElegida = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (horaElegida != null) {
      setState(() {
        timeController.text = "${horaElegida.hour.toString().padLeft(2, '0')}:${horaElegida.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  // --- AÑADIR PUNTO DE RECOGIDA ---
  void _addPickupPoint() {
    if (pickupController.text.trim().isNotEmpty) {
      setState(() {
        puntosRecogida.add(pickupController.text.trim());
        pickupController.clear();
        pickupSuggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Fondo gris claro para que resalten las cajas blancas
      appBar: AppBar(
        title: Text("Crear ruta", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              
              // CONTENEDOR 1: RECORRIDO
              _buildContainer(
                title: "Recorrido",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Origen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: originController,
                      decoration: _inputDeco("Desde dónde sales?", Icon(Icons.circle, color: Colors.blue.shade600, size: 16)),
                      validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      onChanged: (val) async {
                        final sug = await ApiService.getAddressSuggestions(val);
                        setState(() => originSuggestions = sug);
                      },
                    ),
                    if (originSuggestions.isNotEmpty) _buildSuggestions(originSuggestions, originController),
                    
                    SizedBox(height: 15),
                    
                    Text("Destino", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: destinationController,
                      decoration: _inputDeco("A dónde vas?", Icon(Icons.location_on, color: Colors.red, size: 20)),
                      validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                      onChanged: (val) async {
                        final sug = await ApiService.getAddressSuggestions(val);
                        setState(() => destinationSuggestions = sug);
                      },
                    ),
                    if (destinationSuggestions.isNotEmpty) _buildSuggestions(destinationSuggestions, destinationController),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // CONTENEDOR 2: FECHA Y HORA
              _buildContainer(
                title: "Fecha y hora",
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Fecha de inicio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 5),
                          TextFormField(
                            controller: dateController, readOnly: true, onTap: _seleccionarFecha,
                            decoration: _inputDeco("DD/MM/AAAA", Icon(Icons.calendar_today, size: 18)),
                            validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hora", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 5),
                          TextFormField(
                            controller: timeController, readOnly: true, onTap: _seleccionarHora,
                            decoration: _inputDeco("00:00", Icon(Icons.access_time, size: 18)),
                            validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // CONTENEDOR 3: DETALLES DEL VIAJE
              _buildContainer(
                title: "Detalles del viaje",
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Plazas disponibles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 5),
                          TextFormField(
                            controller: seatsController, keyboardType: TextInputType.number,
                            decoration: _inputDeco("Nº", Icon(Icons.event_seat, size: 18)),
                            validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Frecuencia de viaje", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: frecuenciaSeleccionada,
                            decoration: _inputDeco("", null),
                            icon: Icon(Icons.keyboard_arrow_down, size: 20),
                            items: opcionesFrecuencia.map((String valor) {
                              return DropdownMenuItem<String>(value: valor, child: Text(valor, style: TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (val) => setState(() => frecuenciaSeleccionada = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // CONTENEDOR 4: PUNTOS DE RECOGIDA
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
                            decoration: _inputDeco("Añadir dirección...", Icon(Icons.add_location_alt, size: 18)),
                            onChanged: (val) async {
                              final sug = await ApiService.getAddressSuggestions(val);
                              setState(() => pickupSuggestions = sug);
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(color: Color(0xFF5F2C82), borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: _addPickupPoint,
                          ),
                        )
                      ],
                    ),
                    if (pickupSuggestions.isNotEmpty) _buildSuggestions(pickupSuggestions, pickupController),
                    
                    // Lista de puntos añadidos
                    if (puntosRecogida.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          children: puntosRecogida.map((punto) => Chip(
                            label: Text(punto, style: TextStyle(fontSize: 12)),
                            deleteIcon: Icon(Icons.cancel, size: 18),
                            onDeleted: () => setState(() => puntosRecogida.remove(punto)),
                            backgroundColor: Colors.grey.shade200,
                          )).toList(),
                        ),
                      )
                  ],
                ),
              ),
              SizedBox(height: 15),

              // CONTENEDOR 5: PREFERENCIAS DEL VIAJE
              _buildContainer(
                title: "Preferencias del viaje",
                child: Column(
                  children: [
                    _buildCheckboxRow("😶", "Viaje sin conversar", prefSinConversar, (val) => setState(() => prefSinConversar = val!)),
                    _buildCheckboxRow("💼", "Equipaje permitido", prefEquipaje, (val) => setState(() => prefEquipaje = val!)),
                    _buildCheckboxRow("🎵", "Música durante el viaje", prefMusica, (val) => setState(() => prefMusica = val!)),
                    _buildCheckboxRow("🚬", "Fumar permitido", prefFumar, (val) => setState(() => prefFumar = val!)),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // CONTENEDOR 6: REPARTO DE GASTOS
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
                        style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25),

              // BOTÓN PUBLICAR RUTA
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5F2C82), // Morado corporativo
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Publicar Ruta", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS REUTILIZABLES ---

  // Crea la caja con borde gris y título arriba a la izquierda
  Widget _buildContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  // Estilo de los TextFields
  InputDecoration _inputDeco(String hint, Icon? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: icon,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFF5F2C82))),
    );
  }

  // Dibuja la caja de sugerencias del mapa debajo del input
  Widget _buildSuggestions(List<String> list, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, idx) => ListTile(
          dense: true,
          leading: Icon(Icons.location_city, size: 18),
          title: Text(list[idx], style: TextStyle(fontSize: 12)),
          onTap: () => setState(() {
            controller.text = list[idx];
            list.clear();
          }),
        ),
      ),
    );
  }

  // Fila para cada Checkbox de preferencias
  Widget _buildCheckboxRow(String emoji, String title, bool value, Function(bool?) onChanged) {
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
            activeColor: Color(0xFF5F2C82), // Morado
          ),
        ],
      ),
    );
  }
}