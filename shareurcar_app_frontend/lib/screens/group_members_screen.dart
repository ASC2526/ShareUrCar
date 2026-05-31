import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final int? groupId;
  final Map user;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.user,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<dynamic> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  void fetchMembers() async {
    try {
      final data = await ApiService.getGroupMembers(widget.groupId!);
      setState(() {
        members = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error cargando integrantes"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void mostrarOpcionesMiembro(
    BuildContext context,
    Map miembro,
    bool canReview,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Acciones para ${miembro['fullName']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              icon: Icon(Icons.message, color: Color(0xFF5F2C82)),
              label: Text(
                "Enviar mensaje privado",
                style: TextStyle(color: Colors.black87),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Chat privado en desarrollo...")),
                );
              },
            ),
            if (canReview)
              TextButton.icon(
                icon: Icon(Icons.star, color: Colors.orange),
                label: Text(
                  "Añadir reseña al conductor",
                  style: TextStyle(color: Colors.black87),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  mostrarDialogoFormularioResena(context, miembro['idUser']);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void mostrarDialogoFormularioResena(BuildContext context, int targetUserId) {
    final TextEditingController comentarioController = TextEditingController();
    double estrellas = 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Valorar al conductor"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Puntuación: ${estrellas.toInt()} estrellas",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: estrellas,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: Colors.orange,
                onChanged: (value) => setStateDialog(() => estrellas = value),
              ),
              TextField(
                controller: comentarioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Escribe tu opinión sobre el viaje...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                final miUserId =
                    widget.user['idUser'] ??
                    widget.user['id_user'] ??
                    widget.user['id'];

                Map<String, dynamic> dataResena = {
                  "idReviewer": miUserId,
                  "stars": estrellas.toInt(),
                  "comment": comentarioController.text,
                };

                try {
                  await ApiService.createReview(targetUserId, dataResena);
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("¡Reseña guardada con éxito!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error al guardar reseña"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Guardar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.user['idUser'] ?? widget.user['id_user'];

    bool soyPasajero = false;
    for (var m in members) {
      if (m['idUser'] == currentUserId && m['role'] == "Pasajero") {
        soyPasajero = true;
        break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 50, 20, 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chat de grupo",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "👥 ${members.length} participantes",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF5F2C82)),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final bool isMe = member['idUser'] == currentUserId;
                      final bool isDriver = member['role'] == "Conductor";
                      final bool canReview = !isMe && isDriver && soyPasajero;

                      return GestureDetector(
                        onTap: () {
                          if (!isMe) {
                            mostrarOpcionesMiembro(context, member, canReview);
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 15),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Color.fromRGBO(
                                  95,
                                  44,
                                  130,
                                  0.1,
                                ),
                                backgroundImage: member['profilePhoto'] != null
                                    ? NetworkImage(member['profilePhoto'])
                                    : null,
                                child: member['profilePhoto'] == null
                                    ? Icon(
                                        Icons.person,
                                        color: Color(0xFF5F2C82),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            member['fullName'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isMe)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF5F2C82),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Tú",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDriver
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        member['role'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
