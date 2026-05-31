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
  final ScrollController _scrollController = ScrollController();
  int totalParticipantes = 0;

  @override
  void initState() {
    super.initState();
    loadGroupId();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadGroupId() async {
    try {
      final routeId =
          widget.ruta['idRoute'] ??
          widget.ruta['id_route'] ??
          widget.ruta['id'];

      if (routeId == null) {
        throw Exception("No se encontró el ID de la ruta");
      }

      final result = await ApiService.getGroupIdByRoute(
        int.parse(routeId.toString()),
      );

      if (mounted) {
        setState(() => groupId = result);
      }
      await fetchMessages();
      await loadMembersCount();
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error cargando el chat del grupo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchMessages() async {
    if (groupId == null) return;
    try {
      final data = await ApiService.getGroupMessages(groupId!);
      if (mounted) {
        setState(() {
          messages = data;
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error cargando mensajes"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || groupId == null) return;

    final userId = widget.user['idUser'] ?? widget.user['id_user'];

    messageController.clear();

    try {
      await ApiService.sendMessage({
        "idGroup": groupId,
        "idUser": userId,
        "text": text,
      });
      await fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error enviando mensaje"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirIntegrantes() {
    if (groupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cargando integrantes...")));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GroupMembersScreen(groupId: groupId!, user: widget.user),
      ),
    );
  }

  Future<void> loadMembersCount() async {
    if (groupId == null) return;

    final members = await ApiService.getGroupMembers(groupId!);

    if (mounted) {
      setState(() {
        totalParticipantes = members.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final destino = widget.ruta['destination'] ?? "Chat del viaje";
    final currentUserId = widget.user['idUser'] ?? widget.user['id_user'];

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBF8),

      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.white),
        title: GestureDetector(
          onTap: _abrirIntegrantes,
          child: Column(
            children: [
              Text(
                destino,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "👥 $totalParticipantes participantes",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            onPressed: _abrirIntegrantes,
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5F2C82)),
                  )
                : messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Todavía no hay mensajes.\n¡Sé el primero en escribir!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final bool isMine = msg['idUser'] == currentUserId;
                      return _buildMessageBubble(msg, isMine);
                    },
                  ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isMine ? 50 : 0,
          right: isMine ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMine
              ? const LinearGradient(
                  colors: [Color(0xFF5F2C82), Color(0xFF7B3FA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMine ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg['fullName'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F2C82),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (msg['isDriver'] == true)
                          ? Colors.green
                          : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (msg['isDriver'] == true) ? "Conductor" : "Pasajero",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
            ],
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
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF0EBF8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
