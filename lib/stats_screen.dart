import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Aktualisiert die Anzeige (für den Countdown) jede Sekunde
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

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
                const SizedBox(height: 16),

                // --- TOGGLE FÜR DEN WECKER ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text("Baby-Alarm (Wecker) aktiv", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Schalte dies an, damit das Handy random klingelt."),
                    activeColor: Colors.red,
                    value: baby.isAlarmEnabled,
                    onChanged: (bool value) {
                      baby.toggleAlarm(value);
                    },
                  ),
                ),

                // --- COUNTDOWN ANZEIGE ---
                if (baby.isAlarmEnabled) ...[
                  const SizedBox(height: 12),
                  _buildCountdown(baby),
                ],

                const SizedBox(height: 8),
                Text(
                  "Je höher der Stress, desto öfter klingelt der Baby-Alarm!",
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

  Widget _buildCountdown(BabyController baby) {
    final nextTime = baby.nextAlarmTime;
    if (nextTime == null) return const SizedBox.shrink();

    final diff = nextTime.difference(DateTime.now());

    if (diff.isNegative) {
      return _buildRow("Nächster Alarm in:", "Klingelt gleich...", isAlert: true);
    }

    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    // Formatierung (z.B. 01:05)
    final timeString = "${minutes}m ${seconds.toString().padLeft(2, '0')}s";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: diff.inSeconds < 30 ? Colors.red[200] : Colors.green[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: diff.inSeconds < 30 ? Colors.red : Colors.green, width: 2),
      ),
      child: _buildRow("Nächster Alarm in:", timeString, isAlert: diff.inSeconds < 30),
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
                color: isAlert ? Colors.red[900] : Colors.black
            ),
          ),
        ],
      ),
    );
  }
}