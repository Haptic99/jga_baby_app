import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistiken & Zustand"),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            title: "Gesundheits- & Stress-Status",
            color: Colors.red[100]!,
            content: Column(
              children: [
                _buildRow("Mageninhalt:", "${baby.hunger.toStringAsFixed(1)}%"),
                _buildRow("Chill-Faktor:", "${baby.chillLevel.toStringAsFixed(1)}%"),
                const Divider(),
                _buildRow("Babys Stress-Level:", "${baby.babyStress.toStringAsFixed(1)} / 100",
                    isAlert: baby.babyStress > 70),
                const SizedBox(height: 8),
                Text(
                  "Je höher der Stress, desto öfter klingelt der Baby-Alarm im gesperrten Zustand!",
                  style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: "Achievements & Zähler",
            color: Colors.blue[50]!,
            content: Column(
              children: [
                _buildRow("Schulden in CHF:", baby.debt.toStringAsFixed(2)),
                _buildRow("Gegessene Döner:", "${baby.donersEaten}"),
                _buildRow("Gerauchte Joints:", "${baby.jointsSmoked}"),
                _buildRow("Todesfälle:", "${baby.deathsCount}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Color color, required Widget content}) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isAlert ? Colors.red : Colors.black
            ),
          ),
        ],
      ),
    );
  }
}