import 'package:flutter/material.dart';
import '../app_theme.dart';

class PreferenciasCard extends StatelessWidget {
  final Map ruta;
  const PreferenciasCard({super.key, required this.ruta});

  bool _pref(String camel, String snake) =>
      ruta[camel] == true || ruta[snake] == true || ruta[camel] == 1;

  @override
  Widget build(BuildContext context) {
    final allowRoundTrip = _pref('allowRoundTrip', 'allow_round_trip');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: kPrimary),
              SizedBox(width: 10),
              Text(
                "Preferencias del conductor",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Banner ida/vuelta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: allowRoundTrip ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: allowRoundTrip
                    ? Colors.green.shade300
                    : Colors.red.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allowRoundTrip ? Icons.swap_horiz : Icons.block,
                  color: allowRoundTrip ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  allowRoundTrip
                      ? "Ruta con ida y vuelta"
                      : "Solo viaje de ida",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: allowRoundTrip
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),

          CheckboxListTile(
            value: _pref('prefNoTalk', 'pref_no_talk'),
            onChanged: null,
            title: const Text("😶 Viaje sin conversar"),
            dense: true,
          ),
          CheckboxListTile(
            value: _pref('prefLuggage', 'pref_luggage'),
            onChanged: null,
            title: const Text("💼 Equipaje permitido"),
            dense: true,
          ),
          CheckboxListTile(
            value: _pref('prefMusic', 'pref_music'),
            onChanged: null,
            title: const Text("🎵 Música durante el viaje"),
            dense: true,
          ),
          CheckboxListTile(
            value: _pref('prefSmoke', 'pref_smoke'),
            onChanged: null,
            title: const Text("🚬 Fumar permitido"),
            dense: true,
          ),
        ],
      ),
    );
  }
}
