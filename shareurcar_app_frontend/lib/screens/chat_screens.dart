import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shareurcar_app_frontend/screens/group_chat_screen.dart';
import '../services/api_service.dart';

class ChatsScreen extends StatefulWidget {
  final Map user;

  const ChatsScreen({
    super.key,
    required this.user,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {

  List dynamicChats = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  void fetchChats() async {

    setState(() => isLoading = true);

    try {

      final userId =
          widget.user['idUser'] ??
          widget.user['id_user'];

      final chats =
          await ApiService.getUserChats(
              int.parse(userId.toString())
          );

      setState(() {
        dynamicChats = chats;
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error cargando chats"),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      setState(() => isLoading = false);

    }
  }

  String formatTime(dynamic time) {

    try {

      if (time == null) return "";

      final parsed =
          DateFormat("HH:mm:ss")
              .parse(time.toString());

      return DateFormat("HH:mm")
          .format(parsed);

    } catch (e) {

      return "";

    }
  }

  @override
  Widget build(BuildContext context) {

    final String nombreUsuario = widget.user['firstname'] ?? 'Usuario';
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20,
                50,
                20,
                25
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5F2C82),
                  Color(0xFF49A09D),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),

              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Chats",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Hola $nombreUsuario",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F2C82),
                      ),
                    )
                  : dynamicChats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 70,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 15),
                              Text(
                                "No tienes chats activos",
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: dynamicChats.length,
                          itemBuilder: (context, index) {
                            final chat =
                                dynamicChats[index];
                            final ruta =
                                chat['ruta'];
                            return _buildChatCard(
                              destino:
                                  chat['destination'] ??
                                  'Destino',
                              lastMessage:
                                  chat['lastMessage'] ??
                                  '',
                              hora:
                                  formatTime(
                                      chat['travel_time']),
                              ruta: ruta,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard({
    required String destino,
    required String lastMessage,
    required String hora,
    required dynamic ruta,

  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 4),
          )
        ],
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  ruta: ruta,
                  user: widget.user,
                ),
              ),
            );
          },

          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(
                        95,
                        44,
                        130,
                        0.1
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat,
                    color: Color(0xFF5F2C82),
                    size: 26,
                  ),
                ),

                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              destino,
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                                color:
                                    Colors.black87,
                              ),
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ),

                          Text(
                            hora,
                            style: TextStyle(
                              color:
                                  Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}