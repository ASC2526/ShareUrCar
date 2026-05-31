import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;
  final String nombre;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.nombre,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic> userData = {};
  List<dynamic> resenas = [];
  bool isLoading = true;
  double valoracionMedia = 0.0;
  int totalViajes = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final user = await ApiService.getUserById(widget.userId);
      final reviews = await ApiService.getUserReviews(widget.userId);
      final viajes = await ApiService.getCompletedTripsCount(widget.userId);

      double suma = 0;
      for (var r in reviews) {
        suma += (r['stars'] ?? 0);
      }

      if (mounted) {
        setState(() {
          userData = user;
          resenas = reviews;
          totalViajes = viajes;
          if (resenas.isNotEmpty) valoracionMedia = suma / resenas.length;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _obtenerIniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return "${partes[0][0]}${partes[1][0]}".toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : "?";
  }

  String _formatearFecha(String? fechaISO) {
    if (fechaISO == null) return "este mes";
    try {
      final fecha = DateTime.parse(fechaISO);
      const meses = [
        "Ene",
        "Feb",
        "Mar",
        "Abr",
        "May",
        "Jun",
        "Jul",
        "Ago",
        "Sep",
        "Oct",
        "Nov",
        "Dic",
      ];
      return "${meses[fecha.month - 1]} ${fecha.year}";
    } catch (_) {
      return fechaISO;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF5F2C82),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final String nombre =
        userData['firstname'] ?? widget.nombre.split(' ').first;
    final String apellido = userData['lastname'] ?? '';
    final String? fotoUrl = userData['profile_photo'];
    final String iniciales = _obtenerIniciales("$nombre $apellido");
    final String telefono = userData['phone'] ?? "No disponible";
    final String sobreMi =
        userData['aboutMe'] ?? "Todavía no se ha añadido una descripción.";
    final String fechaCreacion =
        userData['createdAt'] ?? userData['created_at'] ?? '';
    final bool tieneCoche =
        userData['carPlate'] != null || userData['car_plate'] != null;

    return Scaffold(
      backgroundColor: const Color(0xFF5F2C82),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: BackButton(color: Colors.white),
        title: Text(
          "$nombre $apellido",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF00E5FF),
                  backgroundImage:
                      (fotoUrl != null && fotoUrl.startsWith('http'))
                      ? NetworkImage(fotoUrl)
                      : null,
                  child: fotoUrl == null
                      ? Text(
                          iniciales,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$nombre $apellido",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.yellowAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            valoracionMedia.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "(${resenas.length})",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (fechaCreacion.isNotEmpty)
                        Text(
                          "Miembro desde ${_formatearFecha(fechaCreacion)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Estadísticas
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        "$totalViajes",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Viajes completados",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.white30),
                  Column(
                    children: [
                      Text(
                        "${resenas.length}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Valoraciones",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: const Color(0xFF49A09D),
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: const Color(0xFF49A09D),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      tabs: [
                        const Tab(text: "Información"),
                        Tab(text: "Reseñas (${resenas.length})"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab Información
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Contacto",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _infoRow(
                                  Icons.phone_outlined,
                                  "Teléfono: ",
                                  telefono,
                                ),
                                const SizedBox(height: 10),
                                _infoRow(
                                  Icons.school_outlined,
                                  "Centro: ",
                                  userData['center'] ?? "No especificado",
                                ),
                                const SizedBox(height: 25),
                                const Text(
                                  "Sobre mí",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  sobreMi,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    height: 1.4,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 25),
                                const Text(
                                  "Vehículo",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: tieneCoche
                                      ? Column(
                                          children: [
                                            _vehicleRow(
                                              "Modelo:",
                                              userData['carModel'] ??
                                                  userData['car_model'] ??
                                                  "Desconocido",
                                            ),
                                            Divider(
                                              color: Colors.grey.shade300,
                                              height: 20,
                                            ),
                                            _vehicleRow(
                                              "Color:",
                                              userData['carColor'] ??
                                                  userData['car_color'] ??
                                                  "Desconocido",
                                            ),
                                            Divider(
                                              color: Colors.grey.shade300,
                                              height: 20,
                                            ),
                                            _vehicleRow(
                                              "Matrícula:",
                                              userData['carPlate'] ??
                                                  userData['car_plate'] ??
                                                  "Desconocida",
                                            ),
                                          ],
                                        )
                                      : Center(
                                          child: Text(
                                            "No tiene vehículo registrado",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),

                          // Tab Reseñas
                          resenas.isEmpty
                              ? Center(
                                  child: Text(
                                    "Todavía no hay reseñas.",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: resenas.length,
                                  itemBuilder: (context, index) {
                                    final r = resenas[index];
                                    final reviewer = r['reviewer'] ?? {};
                                    final String nRv =
                                        reviewer['firstname'] ?? 'Usuario';
                                    final String aRv =
                                        reviewer['lastname'] ?? '';
                                    final String nombreRv = aRv.isEmpty
                                        ? nRv
                                        : "$nRv $aRv";
                                    final int estrellas = r['stars'] ?? 5;
                                    final String comentario =
                                        r['comment'] ?? '';
                                    final String fecha = _formatearFecha(
                                      r['createdAt'] ?? r['created_at'],
                                    );

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: const Color(
                                                    0xFF49A09D,
                                                  ),
                                                  child: Text(
                                                    _obtenerIniciales(nombreRv),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        nombreRv,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: List.generate(
                                                          5,
                                                          (i) => Icon(
                                                            Icons.star,
                                                            size: 14,
                                                            color: i < estrellas
                                                                ? Colors.amber
                                                                : Colors
                                                                      .grey
                                                                      .shade300,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  fecha,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (comentario.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                comentario,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String titulo, String valor) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5F2C82), size: 20),
        const SizedBox(width: 12),
        Text(
          titulo,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _vehicleRow(String titulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          valor,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
