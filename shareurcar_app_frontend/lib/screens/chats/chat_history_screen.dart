import 'package:flutter/material.dart';
import 'package:shareurcar_app_frontend/screens/chats/group_chat_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  final Map user;
  final List todosLosChats;

  const ChatHistoryScreen({
    super.key,
    required this.user,
    required this.todosLosChats,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtro = '';
  String _ordenSeleccionado = 'fecha';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _chatsFiltrados {
    final lista = widget.todosLosChats
        .map((c) => Map<String, dynamic>.from(c as Map))
        .toList();

    List<Map<String, dynamic>> resultado = lista;

    if (_filtro.isNotEmpty) {
      final q = _filtro.toLowerCase();
      resultado = lista.where((c) {
        final destino = (c['destination'] ?? '').toString().toLowerCase();
        final origin = (c['origin'] ?? '').toString().toLowerCase();
        final driver = (c['driverName'] ?? '').toString().toLowerCase();
        final fecha = (c['travel_date'] ?? '').toString().toLowerCase();
        return destino.contains(q) ||
            origin.contains(q) ||
            driver.contains(q) ||
            fecha.contains(q);
      }).toList();
    }

    resultado.sort((a, b) {
      switch (_ordenSeleccionado) {
        case 'conductor':
          return (a['driverName'] ?? '').toString().toLowerCase().compareTo(
            (b['driverName'] ?? '').toString().toLowerCase(),
          );
        case 'destino':
          return (a['destination'] ?? '').toString().toLowerCase().compareTo(
            (b['destination'] ?? '').toString().toLowerCase(),
          );
        default:
          final dA = a['travel_date']?.toString() ?? '';
          final dB = b['travel_date']?.toString() ?? '';
          if (dA.isEmpty) return 1;
          if (dB.isEmpty) return -1;
          return dA.compareTo(dB);
      }
    });

    return resultado;
  }

  String _fechaRelativa(String? fechaIso) {
    if (fechaIso == null) return "Sin fecha";
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
      if (diff == -1) return "Ayer";
      if (diff < 0) return "Hace ${diff.abs()} días";
      return "";
    } catch (_) {
      return fechaIso;
    }
  }

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "";
    try {
      final fecha = DateTime.parse(fechaIso);
      const dias = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
      return "${dias[fecha.weekday - 1]} "
          "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (_) {
      return fechaIso;
    }
  }

  String _formatearHora(String? hora) {
    if (hora == null) return "";
    try {
      return hora.length >= 5 ? hora.substring(0, 5) : hora;
    } catch (_) {
      return hora;
    }
  }

  Color _colorEstado(String? status, String? fechaIso) {
    if (status == 'COMPLETED') return Colors.grey.shade400;
    try {
      if (fechaIso == null) return Colors.grey.shade400;
      final fecha = DateTime.parse(fechaIso);
      final hoy = DateTime.now();
      final diff = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
      ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
      if (diff == 0) return Colors.green;
      if (diff > 0) return Color(0xFF5F2C82);
      return Colors.grey.shade400;
    } catch (_) {
      return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsFiltrados = _chatsFiltrados;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Historial de chats",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filtro = val),
                  decoration: InputDecoration(
                    hintText: "Buscar por destino, origen o conductor...",
                    prefixIcon: Icon(Icons.search, color: Color(0xFF5F2C82)),
                    suffixIcon: _filtro.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filtro = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "Ordenar: ",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 8),
                    _chipOrden("Fecha", "fecha", Icons.calendar_today),
                    SizedBox(width: 8),
                    _chipOrden("Conductor", "conductor", Icons.person_outline),
                    SizedBox(width: 8),
                    _chipOrden(
                      "Destino",
                      "destino",
                      Icons.location_on_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${chatsFiltrados.length} chat(s)",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ),

          Expanded(
            child: chatsFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "No se encontraron chats",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: chatsFiltrados.length,
                    itemBuilder: (context, index) {
                      final chat = chatsFiltrados[index];
                      return _buildHistoryCard(chat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipOrden(String label, String valor, IconData icono) {
    final seleccionado = _ordenSeleccionado == valor;
    return GestureDetector(
      onTap: () => setState(() => _ordenSeleccionado = valor),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? Color(0xFF5F2C82) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              size: 13,
              color: seleccionado ? Colors.white : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: seleccionado ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map chat) {
    final destino = chat['destination'] ?? 'Destino';
    final origin = chat['origin'] ?? '';
    final lastMessage = chat['lastMessage'] ?? '';
    final driverName = chat['driverName'] ?? 'Conductor';
    final fechaRelativa = _fechaRelativa(chat['travel_date']?.toString());
    final fechaFormateada = _formatearFecha(chat['travel_date']?.toString());
    final hora = _formatearHora(chat['travel_time']?.toString());
    final status = chat['status']?.toString();
    final completado = status == 'COMPLETED';
    final colorEstado = _colorEstado(status, chat['travel_date']?.toString());
    final ruta = chat['ruta'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: completado ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completado ? Colors.grey.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completado ? Icons.check_circle_outline : Icons.chat,
                    color: colorEstado,
                    size: 22,
                  ),
                ),

                SizedBox(width: 12),

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
                                fontSize: 15,
                                color: completado
                                    ? Colors.grey.shade500
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              completado ? "Completado" : fechaRelativa,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4),

                      if (origin.isNotEmpty)
                        Text(
                          "Desde: $origin",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                      SizedBox(height: 3),

                      Text(
                        hora.isNotEmpty
                            ? "$fechaFormateada · $hora"
                            : fechaFormateada,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),

                      SizedBox(height: 3),

                      // Conductor
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 13,
                            color: Color(0xFF49A09D),
                          ),
                          SizedBox(width: 4),
                          Text(
                            driverName,
                            style: TextStyle(
                              color: Color(0xFF49A09D),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 5),

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

                Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
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
