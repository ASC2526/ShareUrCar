import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/chat_history_screen.dart';
import 'package:shareurcar_app_frontend/screens/group_chat_screen.dart';
import '../services/api_service.dart';

class ChatsScreen extends StatefulWidget {
  final Map user;

  const ChatsScreen({super.key, required this.user});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List _todosLosChats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  void fetchChats() async {
    setState(() => isLoading = true);
    try {
      final userId = widget.user['idUser'] ?? widget.user['id_user'];
      final chats = await ApiService.getUserChats(int.parse(userId.toString()));
      if (mounted) {
        setState(() {
          _todosLosChats = chats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error cargando chats"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List get _chatsActivos =>
      _todosLosChats.where((c) => c['status'] != 'COMPLETED').toList();

  String _fechaRelativa(String? fechaIso) {
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
      if (diff > 1) return "En $diff días";
      if (diff < 0) return "Hace ${diff.abs()} días";
      return "";
    } catch (_) {
      return "";
    }
  }

  Color _colorBadge(String? fechaIso) {
    if (fechaIso == null) return Colors.grey;
    try {
      final fecha = DateTime.parse(fechaIso);
      final hoy = DateTime.now();
      final diff = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
      ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
      if (diff == 0) return Colors.green;
      if (diff == 1) return Color(0xFF49A09D);
      if (diff <= 3) return Color(0xFF5F2C82);
      return Colors.grey.shade500;
    } catch (_) {
      return Colors.grey;
    }
  }

  String _formatearHora(String? hora) {
    if (hora == null) return "";
    try {
      final partes = hora.split(":");
      return "${partes[0]}:${partes[1]}";
    } catch (_) {
      return hora;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombreUsuario = widget.user['firstname'] ?? 'Usuario';
    final chatsActivos = _chatsActivos;

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chats",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Hola $nombreUsuario · ${chatsActivos.length} activo(s)",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatHistoryScreen(
                          user: widget.user,
                          todosLosChats: _todosLosChats,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Historial",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F2C82),
                      ),
                    )
                  : chatsActivos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Únete a una ruta para empezar a chatear",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => fetchChats(),
                      color: Color(0xFF5F2C82),
                      child: ListView.builder(
                        itemCount: chatsActivos.length,
                        itemBuilder: (context, index) {
                          final chat = chatsActivos[index];
                          return _buildChatCard(chat);
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(Map chat) {
    final destino = chat['destination'] ?? 'Destino';
    final origin = chat['origin'] ?? '';
    final lastMessage = chat['lastMessage'] ?? '';
    final fechaRelativa = _fechaRelativa(chat['travel_date']?.toString());
    final hora = _formatearHora(chat['travel_time']?.toString());
    final driverName = chat['driverName'] ?? 'Conductor';
    final colorBadge = _colorBadge(chat['travel_date']?.toString());
    final ruta = chat['ruta'];

    return Container(
      margin: EdgeInsets.only(bottom: 15),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (ruta == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  ruta: Map<String, dynamic>.from(ruta),
                  user: widget.user,
                ),
              ),
            ).then((_) => fetchChats());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(95, 44, 130, 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat, color: Color(0xFF5F2C82), size: 24),
                ),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              destino,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (fechaRelativa.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorBadge,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fechaRelativa,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 5),

                      // Origen
                      if (origin.isNotEmpty)
                        Text(
                          "Desde: $origin",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                      SizedBox(height: 4),

                      // Conductor + hora
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Color(0xFF49A09D),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hora.isNotEmpty
                                  ? "$driverName · $hora"
                                  : driverName,
                              style: TextStyle(
                                color: Color(0xFF49A09D),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 6),

                      // Último mensaje
                      Text(
                        lastMessage.isNotEmpty
                            ? lastMessage
                            : "Sin mensajes aún",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: lastMessage.isNotEmpty
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          fontSize: 13,
                          fontStyle: lastMessage.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
