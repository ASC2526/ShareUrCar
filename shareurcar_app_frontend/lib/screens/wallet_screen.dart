import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  final Map user;

  const WalletScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    double balance = (user['balance'] ?? 0).toDouble();

    double held = (user['heldBalance'] ?? user['held_balance'] ?? 0).toDouble();

    double available = balance - held;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: Text("Mi saldo", style: TextStyle(fontWeight: FontWeight.bold)),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      body: Padding(
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

                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Saldo disponible",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "${available.toStringAsFixed(2)} €",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            _buildBalanceCard(
              "Saldo retenido",
              held,
              Icons.lock_outline,
              Colors.orange,
            ),

            SizedBox(height: 15),

            _buildBalanceCard(
              "Saldo total",
              balance,
              Icons.account_balance_wallet_outlined,
              Color(0xFF5F2C82),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
