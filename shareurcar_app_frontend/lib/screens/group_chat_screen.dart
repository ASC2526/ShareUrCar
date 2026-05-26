import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/group_members_screen.dart';
import '../services/api_service.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;
  final Map user;

  const GroupChatScreen({super.key, required this.ruta, required this.user});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  List<dynamic> messages = [];
  bool isLoading = true;
  int? groupId;

  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadGroupId();
  }

  Future<void> loadGroupId() async {
    try {
      final routeId = widget.ruta['idRoute'];

      final result = await ApiService.getGroupIdByRoute(routeId);

      setState(() {
        groupId = result;
      });

      fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error cargando grupo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void fetchMessages() async {
    if (groupId == null) return;

    try {
      final data = await ApiService.getGroupMessages(groupId!);

      setState(() {
        messages = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error cargando mensajes"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    if (groupId == null) return;

    try {
      final userId = widget.user['idUser'] ?? widget.user['id_user'];

      await ApiService.sendMessage({
        "idGroup": groupId,
        "idUser": userId,
        "text": messageController.text.trim(),
      });

      messageController.clear();

      fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error enviando mensaje"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destino = widget.ruta['destination'] ?? "Chat del viaje";

    final currentUserId = widget.user['idUser'] ?? widget.user['id_user'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        centerTitle: true,

        leading: BackButton(color: Colors.black87),

        title: GestureDetector(
          onTap: () {
            if (groupId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Cargando integrantes...")),
              );

              return;
            }

            Navigator.push(
              context,

              MaterialPageRoute(
                builder: (_) =>
                    GroupMembersScreen(groupId: groupId!, user: widget.user),
              ),
            );
          },

          child: Column(
            children: [
              Text(
                destino,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              Text(
                "Chat del grupo",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF5F2C82)),
                  )
                : messages.isEmpty
                ? Center(
                    child: Text(
                      "Todavía no hay mensajes",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(20),

                    itemCount: messages.length,

                    itemBuilder: (context, index) {
                      final msg = messages[index];

                      final bool isMine = msg['idUser'] == currentUserId;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,

                        child: Container(
                          margin: EdgeInsets.only(bottom: 12),

                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),

                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),

                          decoration: BoxDecoration(
                            color: isMine ? Color(0xFF5F2C82) : Colors.white,

                            borderRadius: BorderRadius.circular(18),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              if (!isMine)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          msg['fullName'] ?? '',

                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5F2C82),
                                            fontSize: 12,
                                          ),
                                        ),

                                        SizedBox(width: 8),

                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),

                                          decoration: BoxDecoration(
                                            color: msg['isDriver']
                                                ? Colors.green
                                                : Colors.red,

                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),

                                          child: Text(
                                            msg['isDriver']
                                                ? "Conductor"
                                                : "Pasajero",

                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 5),
                                  ],
                                ),

                              Text(
                                msg['text'] ?? '',

                                style: TextStyle(
                                  color: isMine ? Colors.white : Colors.black87,

                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20),

            decoration: BoxDecoration(
              color: Colors.white,

              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,

                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",

                      filled: true,

                      fillColor: Colors.grey.shade100,

                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 10),

                GestureDetector(
                  onTap: sendMessage,

                  child: Container(
                    padding: EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
                      ),

                      shape: BoxShape.circle,
                    ),

                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
