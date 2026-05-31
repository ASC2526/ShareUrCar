import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../app_utils.dart';
import '../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  final Map user;
  const PaymentsScreen({super.key, required this.user});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Map currentUser;
  List<dynamic> payments = [];
  bool loadingPayments = true;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshUser();
    _loadPayments();
  }

  @override
  void didUpdateWidget(covariant PaymentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      currentUser = widget.user;
    }
  }

  Future<void> _refreshUser() async {
    try {
      final updated = await ApiService.getUserById(currentUser['idUser']);
      if (mounted) setState(() => currentUser = updated);
    } catch (_) {}
  }

  Future<void> _loadPayments() async {
    try {
      final data = await ApiService.getUserPayments(currentUser['idUser']);
      if (mounted) {
        setState(() {
          payments = data;
          loadingPayments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingPayments = false);
    }
  }

  Future<void> _updateBalance(double amount) async {
    try {
      await ApiService.updateBalance(currentUser['idUser'], amount);
      await _refreshUser();
      if (mounted) setState(() => loadingPayments = true);
      await _loadPayments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kSecondary,
          content: Text(
            amount > 0
                ? "Saldo añadido correctamente"
                : "Saldo retirado correctamente",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (mounted) setState(() => loadingPayments = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.toString().replaceAll("Exception: ", "")),
        ),
      );
    }
  }

  void _showBalanceDialog(bool add) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(add ? "Añadir saldo" : "Retirar saldo"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Cantidad",
            suffixText: "€",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cantidad inválida")),
                );
                return;
              }
              Navigator.pop(context);
              await _updateBalance(add ? amount : -amount);
            },
            child: Text(
              add ? "Añadir" : "Retirar",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // interpreta un pago y devuelve título, icono, color y signo
  _PaymentDisplay _displayFor(Map payment) {
    final type = payment['paymentType'] ?? '';
    final status = payment['paymentStatus'] ?? '';
    final amount = (payment['amount'] ?? 0).toDouble();

    if (type == 'TRIP_PAYMENT' && status == 'CANCELLED') {
      return _PaymentDisplay(
        title: "Reembolso (viaje cancelado)",
        amount: "+${amount.toStringAsFixed(2)} €",
        icon: Icons.reply,
        color: Colors.blue,
      );
    }

    switch (type) {
      case 'DEPOSIT':
        return _PaymentDisplay(
          title: "Recarga de saldo",
          amount: "+${amount.toStringAsFixed(2)} €",
          icon: Icons.add_circle,
          color: Colors.green,
        );
      case 'WITHDRAW':
        return _PaymentDisplay(
          title: "Retirada de saldo",
          amount: "-${amount.toStringAsFixed(2)} €",
          icon: Icons.remove_circle,
          color: Colors.red,
        );
      case 'TRIP_PAYMENT':
        return _PaymentDisplay(
          title: "Pago de viaje",
          amount: "-${amount.toStringAsFixed(2)} €",
          icon: Icons.directions_car,
          color: Colors.redAccent,
        );
      case 'TRIP_INCOME':
        return _PaymentDisplay(
          title: "Cobro por viaje",
          amount: "+${amount.toStringAsFixed(2)} €",
          icon: Icons.payments,
          color: Colors.green,
        );
      case 'REFUND':
        return _PaymentDisplay(
          title: "Reembolso",
          amount: "+${amount.toStringAsFixed(2)} €",
          icon: Icons.reply,
          color: Colors.blue,
        );
      case 'PRICE_ADJUSTMENT':
        return _PaymentDisplay(
          title: "Ajuste de precio",
          amount: "+${amount.toStringAsFixed(2)} €",
          icon: Icons.savings,
          color: Colors.green,
        );
      default:
        return _PaymentDisplay(
          title: "Movimiento",
          amount: "${amount.toStringAsFixed(2)} €",
          icon: Icons.receipt_long,
          color: Colors.grey,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = AppUtils.saldoDisponible(currentUser);
    final balance = (currentUser['balance'] ?? 0).toDouble();
    final held =
        (currentUser['heldBalance'] ?? currentUser['held_balance'] ?? 0)
            .toDouble();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Gestión de saldo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshUser();
          await _loadPayments();
        },
        color: kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // saldo disponible
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Saldo disponible",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${available.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              _infoCard(
                "Saldo retenido",
                held,
                Icons.lock_outline,
                Colors.orange,
              ),
              const SizedBox(height: 15),
              _infoCard(
                "Saldo total",
                balance,
                Icons.account_balance_wallet,
                kPrimary,
              ),

              const SizedBox(height: 35),

              // botones añadir y retirar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBalanceDialog(true),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Añadir",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBalanceDialog(false),
                      icon: const Icon(Icons.remove, color: Colors.white),
                      label: const Text(
                        "Retirar",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Actividad reciente",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // lista movimientos
              loadingPayments
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    )
                  : payments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Todavía no hay movimientos",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : Column(
                      children: payments.map((p) {
                        final d = _displayFor(Map<String, dynamic>.from(p));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _activityItem(d),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, double amount, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "${amount.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityItem(_PaymentDisplay d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: d.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(d.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              d.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Text(
            d.amount,
            style: TextStyle(
              color: d.color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// objeto de datos para un item de actividad
class _PaymentDisplay {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  const _PaymentDisplay({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });
}
