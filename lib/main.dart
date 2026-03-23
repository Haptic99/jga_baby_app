import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';
import 'smoke_minigame_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BabyController(),
      child: MaterialApp(
        title: 'JGA Baby Watch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const BabyHomeScreen(),
      ),
    ),
  );
}

class BabyHomeScreen extends StatelessWidget {
  const BabyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyController>(context);

    return Scaffold(
      backgroundColor: baby.isAlive ? const Color(0xFFF5F5F5) : Colors.black,
      appBar: AppBar(
        title: const Text("🍼 JGA Baby-Watch 2026"),
        backgroundColor: baby.isAlive ? Colors.orange : Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: baby.isAlive ? _buildLivingUI(context, baby) : _buildDeathUI(context, baby),
          ),
          // Statistik-Button unten in der Mitte
          if (baby.isAlive)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showStats(context, baby),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text("Statistiken"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStats(BuildContext context, BabyController baby) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("JGA Statistik", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(),
              _statRow(Icons.money, "Schulden:", "${baby.debt.toStringAsFixed(2)} CHF", Colors.red),
              _statRow(Icons.fastfood, "Gegessene Döner:", "${baby.donersEaten}", Colors.orange),
              _statRow(Icons.smoke_free, "Gepaffte Joints:", "${baby.jointsSmoked}", Colors.green),
              _statRow(Icons.skull, "Todesfälle:", "${baby.deathsCount}", Colors.black),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(label)]),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLivingUI(BuildContext context, BabyController baby) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("👶", style: TextStyle(fontSize: 120)),
        const SizedBox(height: 20),
        _statusLabel("Mageninhalt (Döner)", baby.hunger, Colors.red),
        _statusLabel("Chill-Faktor (🥦)", baby.chillLevel, Colors.green),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionBtn("Döner", Icons.fastfood, Colors.orange, () => baby.feed(20)),
            _actionBtn("Joint", Icons.smoke_free, Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SmokeMinigameScreen()));
            }),
          ],
        ),
        const SizedBox(height: 100), // Platz für Statistik-Button
      ],
    );
  }

  Widget _buildDeathUI(BuildContext context, BabyController baby) {
    final TextEditingController codeController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("💀", style: TextStyle(fontSize: 100)),
          const Text("BABY TOT!", style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("TRINK EINEN SHOT!\nDann Code eingeben:", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 20),
          TextField(
            controller: codeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)), labelText: "Geheimcode", labelStyle: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => baby.revive(codeController.text),
            child: const Text("WIEDERBELEBEN"),
          ),
        ],
      ),
    );
  }

  Widget _statusLabel(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: value / 100, minHeight: 12, borderRadius: BorderRadius.circular(10), color: color, backgroundColor: color.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _actionBtn(String text, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
    );
  }
}