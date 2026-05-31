import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/edit_profile_screen.dart';
import 'package:shareurcar_app_frontend/screens/wallet_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> resenas = [];
  bool isLoadingReviews = true;
  double valoracionMedia = 0.0;
  late Map currentUser;
  int totalViajes = 0;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _cargarDatosPerfil();
  }

  Future<void> _refreshUserData() async {
    try {
      final userId =
          currentUser['idUser'] ?? currentUser['id_user'] ?? currentUser['id'];
      final updatedUser = await ApiService.getUserById(
        int.parse(userId.toString()),
      );

      if (mounted) {
        setState(() {
          currentUser = updatedUser;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil actualizado correctamente"),
            backgroundColor: Color(0xFF49A09D),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al actualizar el perfil"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      print("Error al refrescar: $e");
    }
  }

  void _cargarDatosPerfil() async {
    final userId =
        currentUser['idUser'] ?? currentUser['id_user'] ?? currentUser['id'];

    final data = await ApiService.getUserReviews(userId);
    final viajes = await ApiService.getCompletedTripsCount(userId);
    double suma = 0;
    for (var r in data) {
      suma += (r['stars'] ?? 0);
    }

    if (mounted) {
      setState(() {
        resenas = data;
        totalViajes = viajes;
        if (resenas.isNotEmpty) valoracionMedia = suma / resenas.length;
        isLoadingReviews = false;
      });
    }
  }

  String _obtenerIniciales(String nombre, String apellido) {
    String inicialNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : "";
    String inicialApellido = apellido.isNotEmpty
        ? apellido[0].toUpperCase()
        : "";
    return "$inicialNombre$inicialApellido";
  }

  String _formatearFecha(String? fechaISO) {
    if (fechaISO == null) return "este mes";
    try {
      final DateTime fecha = DateTime.parse(fechaISO);
      final meses = [
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
    } catch (e) {
      return fechaISO;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = currentUser['firstname'] ?? 'Usuario';
    final String apellido = currentUser['lastname'] ?? '';
    final String iniciales = _obtenerIniciales(nombre, apellido);
    final String? fotoUrl =
        currentUser['profile_photo'] ?? currentUser['profile_photo'];
    final String telefono = currentUser['phone'] ?? "No disponible";
    final String sobreMi =
        currentUser['aboutMe'] ?? "Todavía no se ha añadido una descripción.";
    final String fechaCreacion =
        currentUser['createdAt'] ?? currentUser['created_at'];

    return Scaffold(
      backgroundColor: Color(0xFF5F2C82),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () async {
                final recargar = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: currentUser),
                  ),
                );
                if (recargar == true) {
                  await _refreshUserData();
                }
              },
              icon: Icon(Icons.edit, size: 16, color: Colors.white),
              label: Text(
                "Editar perfil",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF49A09D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  key: ValueKey(fotoUrl),
                  radius: 40,
                  backgroundColor: Color(0xFF00E5FF),
                  backgroundImage:
                      (fotoUrl != null && fotoUrl.startsWith('http'))
                      ? NetworkImage(fotoUrl)
                      : null,
                  child: fotoUrl == null
                      ? Text(
                          iniciales,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$nombre $apellido",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.yellowAccent,
                            size: 18,
                          ),
                          SizedBox(width: 5),
                          Text(
                            valoracionMedia.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            "(${resenas.length})",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Miembro desde ${_formatearFecha(fechaCreacion)}",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // tarjeta estadísticas
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15),
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Valoraciones",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WalletScreen(user: currentUser),
                  ),
                );
                await _refreshUserData();
              },

              child: Container(
                padding: EdgeInsets.all(18),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF49A09D), Color(0xFF5F2C82)],
                  ),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Saldo disponible",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "${((currentUser['balance'] ?? 0) - (currentUser['heldBalance'] ?? currentUser['held_balance'] ?? 0)).toStringAsFixed(2)} €",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 25),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Color(0xFF49A09D),
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: Color(0xFF49A09D),
                      indicatorWeight: 3,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: [
                        Tab(text: "Información"),
                        Tab(text: "Reseñas (${resenas.length})"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildInformacionTab(telefono, sobreMi),
                          _buildResenasTab(),
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

  // INFO
  Widget _buildInformacionTab(String telefono, String sobreMi) {
    final tieneCoche =
        currentUser['carPlate'] != null || currentUser['car_plate'] != null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CONTACTO
          Text(
            "Contacto",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          _buildInfoRow(Icons.phone_outlined, "Teléfono: ", telefono),
          SizedBox(height: 10),
          _buildInfoRow(
            Icons.email_outlined,
            "Email: ",
            currentUser['email'] ?? "No disponible",
          ),
          SizedBox(height: 10),
          _buildInfoRow(
            Icons.school_outlined,
            "Centro: ",
            currentUser['center'] ?? "No especificado",
          ),

          SizedBox(height: 30),

          // SOBRE MÍ
          Text(
            "Sobre mí",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            sobreMi,
            style: TextStyle(
              color: Colors.grey.shade800,
              height: 1.4,
              fontSize: 14,
            ),
          ),

          SizedBox(height: 30),

          // VEHÍCULO
          Text(
            "Vehículo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: tieneCoche
                ? Column(
                    children: [
                      _buildVehicleRow(
                        "Modelo:",
                        currentUser['carModel'] ??
                            currentUser['car_model'] ??
                            "Desconocido",
                      ),
                      Divider(color: Colors.grey.shade300, height: 20),
                      _buildVehicleRow(
                        "Color:",
                        currentUser['carColor'] ??
                            currentUser['car_color'] ??
                            "Desconocido",
                      ),
                      Divider(color: Colors.grey.shade300, height: 20),
                      _buildVehicleRow(
                        "Matrícula:",
                        currentUser['carPlate'] ??
                            currentUser['car_plate'] ??
                            "Desconocida",
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      "No tiene vehículo registrado",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResenasTab() {
    if (isLoadingReviews) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF5F2C82)));
    }

    if (resenas.isEmpty) {
      return Center(
        child: Text(
          "Todavía no hay reseñas.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: resenas.length,
      itemBuilder: (context, index) {
        final resena = resenas[index];

        final reviewer = resena['reviewer'] ?? {};

        final String nombreRv = reviewer['firstname'] ?? 'Usuario';
        final String apellidoRv = reviewer['lastname'] ?? '';
        final String inicialesRv = _obtenerIniciales(nombreRv, apellidoRv);
        final String nombreCompleto = apellidoRv.isEmpty
            ? nombreRv
            : "$nombreRv $apellidoRv";

        final int estrellas = resena['stars'] ?? 5;
        final String comentario = resena['comment'] ?? resena['texto'] ?? '';
        final String fecha = _formatearFecha(
          resena['createdAt'] ?? resena['created_at'],
        );

        return Card(
          margin: EdgeInsets.only(bottom: 15),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF49A09D),
                          child: Text(
                            inicialesRv,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreCompleto,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  Icons.star,
                                  size: 14,
                                  color: starIndex < estrellas
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      fecha,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  comentario,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String titulo, String valor) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF5F2C82), size: 22),
        SizedBox(width: 15),
        Text(
          titulo,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
        Expanded(
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleRow(String titulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
