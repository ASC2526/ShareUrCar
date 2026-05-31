import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  // formato hora
  static String formatHora(String? hora) {
    if (hora == null || hora.isEmpty) return "--:--";
    try {
      final partes = hora.split(":");
      return "${partes[0]}:${partes[1]}";
    } catch (_) {
      return hora;
    }
  }

  // fecha completa
  static String formatFechaCompleta(String? fechaIso) {
    if (fechaIso == null) return "";
    try {
      final fecha = DateTime.parse(fechaIso);
      const dias = [
        "Lunes",
        "Martes",
        "Miércoles",
        "Jueves",
        "Viernes",
        "Sábado",
        "Domingo",
      ];
      return "${dias[fecha.weekday - 1]} "
          "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (_) {
      return fechaIso;
    }
  }

  // versión para listas
  static String formatFechaCorta(String? fechaIso) {
    if (fechaIso == null) return "";
    try {
      final fecha = DateTime.parse(fechaIso);
      const dias = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
      return "${dias[fecha.weekday - 1]} "
          "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}";
    } catch (_) {
      return fechaIso;
    }
  }

  // fecha para perfil
  static String formatFechaMesAnyo(String? fechaIso) {
    if (fechaIso == null) return "este mes";
    try {
      final fecha = DateTime.parse(fechaIso);
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
      return fechaIso;
    }
  }

  // hoy, mañana, en x días...
  static String fechaRelativa(String? fechaIso, {bool incluirPasado = false}) {
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
      if (incluirPasado) {
        if (diff == -1) return "Ayer";
        return "Hace ${diff.abs()} días";
      }
      return "";
    } catch (_) {
      return "";
    }
  }

  // formato fecha largo
  static String formatFechaIntl(String? fechaIso) {
    if (fechaIso == null) return "Fecha sin definir";
    try {
      return DateFormat(
        'EEEE, dd MMMM',
        'es_ES',
      ).format(DateTime.parse(fechaIso));
    } catch (_) {
      return fechaIso;
    }
  }

  // elimina Alicante para limpiar dirección
  static String limpiarDireccion(String dir) =>
      dir.replaceAll(", Alicante", "").trim();

  // iniciales
  static String iniciales(String nombre, [String apellido = ""]) {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : "";
    final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : "";
    return "$n$a";
  }

  // saldo disponible
  static double saldoDisponible(Map user) {
    final bal = (user['balance'] ?? 0).toDouble();
    final held = (user['heldBalance'] ?? user['held_balance'] ?? 0).toDouble();
    return bal - held;
  }

  // idde usuario camelCase y snakecase
  static int userId(Map user) =>
      int.parse((user['idUser'] ?? user['id_user'] ?? user['id']).toString());

  // id ruta paracamelCase y snakecase
  static int? routeId(Map ruta) {
    final raw = ruta['idRoute'] ?? ruta['id_route'] ?? ruta['id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }
}
