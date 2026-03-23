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
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Text(
                "Schulden: ${baby.debt.toStringAsFixed(2)} CHF",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
        backgroundColor: baby.isAlive ? Colors.orange : Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: baby.isAlive ? _buildLivingUI(context, baby) : _buildDeathUI(context, baby),
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
            ElevatedButton.icon(
              onPressed: () => baby.feed(20),
              icon: const Icon(Icons.fastfood),
              label: const Text("Döner"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SmokeMinigameScreen()),
                );
              },
              icon: const Icon(Icons.smoke_free),
              label: const Text("Joint rauchen"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeathUI(BuildContext context, BabyController baby) {
    final TextEditingController codeController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // HIER WAR DER FEHLER - JETZT GEFIXT!
        children: [
          const Text("💀", style: TextStyle(fontSize: 100)),
          const Text(
            "BABY TOT!",
            style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "TRINK EINEN SHOT!\nDann Code eingeben:",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: codeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              labelText: "Geheimcode",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (!baby.revive(codeController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Falscher Code! Trink noch einen!")),
                );
              }
            },
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
          LinearProgressIndicator(
            value: value / 100,
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
            color: color,
            backgroundColor: color.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}