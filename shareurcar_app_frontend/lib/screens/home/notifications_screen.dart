import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  final Map user;

  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool isLoading = true;

  int get _miId =>
      int.parse((widget.user['idUser'] ?? widget.user['id_user']).toString());

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getNotifications(_miId);
      if (mounted) {
        setState(() {
          _notifications = data;
          isLoading = false;
        });
        // marcar todas como leídas al abrir
        await ApiService.markNotificationsAsRead(_miId);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return "";
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return "Ahora";
      if (diff.inMinutes < 60) return "Hace ${diff.inMinutes} min";
      if (diff.inHours < 24) return "Hace ${diff.inHours}h";
      if (diff.inDays == 1) return "Ayer";
      return "Hace ${diff.inDays} días";
    } catch (_) {
      return "";
    }
  }

  IconData _iconForTitle(String title) {
    if (title.contains("⚠️") || title.toLowerCase().contains("incidencia")) {
      return Icons.warning_amber_rounded;
    }
    if (title.contains("✅") || title.toLowerCase().contains("confirmado")) {
      return Icons.check_circle_outline;
    }
    return Icons.notifications_outlined;
  }

  Color _colorForTitle(String title, bool isRead) {
    if (isRead) return Colors.grey.shade500;
    if (title.contains("⚠️") || title.toLowerCase().contains("incidencia")) {
      return Colors.orange;
    }
    if (title.contains("✅") || title.toLowerCase().contains("confirmado")) {
      return Colors.green;
    }
    return const Color(0xFF5F2C82);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Notificaciones",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: () async {
                await ApiService.markNotificationsAsRead(_miId);
                await _loadNotifications();
              },
              child: const Text(
                "Leer todas",
                style: TextStyle(color: Color(0xFF5F2C82)),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2C82)),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "No tienes notificaciones",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: const Color(0xFF5F2C82),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  final bool isRead = notif['isRead'] == true;
                  final String title = notif['title'] ?? '';
                  final String body = notif['body'] ?? '';
                  final String time = _formatTime(
                    notif['createdAt']?.toString(),
                  );
                  final Color color = _colorForTitle(title, isRead);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRead
                            ? Colors.grey.shade200
                            : color.withOpacity(0.3),
                        width: isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForTitle(title),
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // punto de no leído
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 5),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
