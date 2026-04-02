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

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text("Baby-Alarm (Wecker) aktiv", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Schalte dies an, damit das Handy random klingelt."),
                    activeTrackColor: Colors.red,
                    value: baby.isAlarmEnabled,
                    onChanged: (bool value) {
                      baby.toggleAlarm(value);
                    },
                  ),
                ),

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
                _buildRow("Gefütterte Gin-Flaschen:", "${baby.ginBottlesFed}"),
                _buildRow("Todesfälle:", "${baby.deathsCount}"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- NEUE ADMIN KONSOLE ---
          _buildInfoCard(
            title: "Admin / Cheats",
            color: Colors.purple[50]!,
            content: Column(
              children: [
                SwitchListTile(
                  title: const Text("Mageninhalt einfrieren"),
                  value: baby.isHungerPaused,
                  activeColor: Colors.purple,
                  onChanged: (val) => baby.toggleHungerPause(val),
                ),
                SwitchListTile(
                  title: const Text("Chill-Faktor einfrieren"),
                  value: baby.isChillPaused,
                  activeColor: Colors.purple,
                  onChanged: (val) => baby.toggleChillPause(val),
                ),
                // --- HIER IST DER NEUE HARDCORE SCHALTER ---
                SwitchListTile(
                  title: const Text(
                      "Hardcore-Modus (Weed)",
                      style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: const Text(
                      "Zufall aus: Boro braucht ewig zum Antworten."
                  ),
                  value: baby.alwaysUseLongChat,
                  activeColor: Colors.purple,
                  onChanged: (bool value) {
                    baby.toggleLongChat(value);
                  },
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => baby.setHunger(100),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[200]),
                      child: const Text("Magen 100%", style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: () => baby.setChill(100),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[200]),
                      child: const Text("Chill 100%", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Stress anpassen:", style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.green),
                          onPressed: () => baby.modifyStress(-10),
                        ),
                        Text("${baby.babyStress.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.red),
                          onPressed: () => baby.modifyStress(10),
                        ),
                      ],
                    )
                  ],
                ),
                const Divider(),
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    label: const Text("Alle Statistiken zurücksetzen", style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _showResetDialog(context, baby);
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, BabyController baby) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Wirklich zurücksetzen?"),
          content: const Text("Möchtest du alle Schulden und Zähler (Döner, Joints, Gin, Tode) löschen?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                baby.resetStats();
                Navigator.pop(context);
              },
              child: const Text("Zurücksetzen", style: TextStyle(color: Colors.white)),
            )
          ],
        )
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