import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  final Map user;

  const PaymentsScreen({super.key, required this.user});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Map currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    final updatedUser = await ApiService.getUserById(currentUser['idUser']);

    setState(() {
      currentUser = updatedUser;
    });
  }

  Future<void> _updateBalance(double amount) async {
    try {
      await ApiService.updateBalance(currentUser['idUser'], amount);

      await _refreshUser();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF49A09D),

          content: Text(
            amount > 0
                ? "Saldo añadido correctamente"
                : "Saldo retirado correctamente",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,

          content: Text("Operación inválida"),
        ),
      );
    }
  }

  void _showBalanceDialog(bool add) {
    final controller = TextEditingController();

    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(add ? "Añadir saldo" : "Retirar saldo"),

          content: TextField(
            controller: controller,

            keyboardType: TextInputType.number,

            decoration: InputDecoration(
              hintText: "Cantidad",

              suffixText: "€",

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: Text("Cancelar"),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  double amount = double.parse(controller.text);

                  if (amount <= 0) {
                    return;
                  }

                  if (!add) {
                    amount = -amount;
                  }

                  Navigator.pop(context);

                  await _updateBalance(amount);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Cantidad inválida")));
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5F2C82),
              ),

              child: Text(
                add ? "Añadir" : "Retirar",

                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double balance = (currentUser['balance'] ?? 0).toDouble();

    double held =
        (currentUser['heldBalance'] ?? currentUser['held_balance'] ?? 0)
            .toDouble();

    double available = balance - held;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: Text(
          "Gestión de saldo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,

              padding: EdgeInsets.all(25),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5F2C82), Color(0xFF49A09D)],
                ),

                borderRadius: BorderRadius.circular(22),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Saldo disponible",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "${available.toStringAsFixed(2)} €",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            _buildInfoCard(
              "Saldo retenido",
              held,
              Icons.lock_outline,
              Colors.orange,
            ),

            SizedBox(height: 15),

            _buildInfoCard(
              "Saldo total",
              balance,
              Icons.account_balance_wallet,
              Color(0xFF5F2C82),
            ),

            SizedBox(height: 35),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showBalanceDialog(true);
                    },

                    icon: Icon(Icons.add, color: Colors.white),

                    label: Text(
                      "Añadir",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF49A09D),

                      padding: EdgeInsets.symmetric(vertical: 16),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 15),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showBalanceDialog(false);
                    },

                    icon: Icon(Icons.remove, color: Colors.white),

                    label: Text(
                      "Retirar",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,

                      padding: EdgeInsets.symmetric(vertical: 16),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 35),

            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                "Actividad reciente",

                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 18),

            _buildActivityItem(
              "Reserva de viaje",
              "-2.75 €",
              Icons.directions_car,
              Colors.redAccent,
            ),

            SizedBox(height: 12),

            _buildActivityItem(
              "Recarga de saldo",
              "+15.00 €",
              Icons.add_circle_outline,
              Color(0xFF49A09D),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: color),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                SizedBox(height: 4),

                Text(
                  "${amount.toStringAsFixed(2)} €",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: color),
          ),

          SizedBox(width: 15),

          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
