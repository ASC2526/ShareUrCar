import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/profile/public_profile_screen.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';

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
      if (mounted) setState(() => members = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error cargando integrantes"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  int get _miId => int.parse(
    (widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'])
        .toString(),
  );

  void _mostrarOpciones(Map miembro) {
    final bool soyYo = miembro['idUser'] == _miId;
    if (soyYo) return;

    final bool esDriver = miembro['role'] == "Conductor";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            CircleAvatar(
              radius: 28,
              backgroundColor: kPrimary.withOpacity(0.1),
              backgroundImage: miembro['profilePhoto'] != null
                  ? NetworkImage(miembro['profilePhoto'])
                  : null,
              child: miembro['profilePhoto'] == null
                  ? const Icon(Icons.person, color: Color(0xFF5F2C82))
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              miembro['fullName'] ?? '',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: esDriver ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                miembro['role'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Botón ver perfil
            _botonOpcion(
              icono: Icons.person_outline,
              color: const Color(0xFF5F2C82),
              label: "Ver perfil",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                      userId: miembro['idUser'],
                      nombre: miembro['fullName'] ?? '',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Botón añadir reseña
            if (esDriver)
              _botonOpcion(
                icono: Icons.star_outline,
                color: Colors.orange,
                label: "Añadir reseña",
                onTap: () {
                  Navigator.pop(context);
                  _mostrarFormularioResena(miembro['idUser']);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _botonOpcion({
    required IconData icono,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icono, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioResena(int targetUserId) {
    final TextEditingController comentarioController = TextEditingController();
    double estrellas = 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.orange),
              SizedBox(width: 10),
              Text("Valorar al conductor"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${estrellas.toInt()} estrella(s)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: estrellas,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: Colors.orange,
                label: "${estrellas.toInt()}",
                onChanged: (v) => setStateDialog(() => estrellas = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return Icon(
                    i < estrellas.toInt() ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 28,
                  );
                }),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: comentarioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Escribe tu opinión sobre el viaje...",
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
                try {
                  await ApiService.createReview(targetUserId, {
                    "idReviewer": _miId,
                    "stars": estrellas.toInt(),
                    "comment": comentarioController.text.trim(),
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Reseña guardada con éxito!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error al guardar la reseña"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Guardar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Integrantes del grupo",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : members.isEmpty
          ? Center(
              child: Text(
                "No hay integrantes",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final bool isMe = member['idUser'] == _miId;
                final bool isDriver = member['role'] == "Conductor";
                final double rating = (member['rating'] ?? 0).toDouble();

                return GestureDetector(
                  onTap: () => _mostrarOpciones(member),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(
                            0xFF5F2C82,
                          ).withOpacity(0.1),
                          backgroundImage: member['profilePhoto'] != null
                              ? NetworkImage(member['profilePhoto'])
                              : null,
                          child: member['profilePhoto'] == null
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF5F2C82),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      member['fullName'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (isMe)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5F2C82),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
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
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDriver
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      member['role'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (rating > 0) ...[
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isMe)
                          Icon(Icons.more_vert, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
