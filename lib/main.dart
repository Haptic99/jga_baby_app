import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';

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
      body: Center(
        child: baby.isAlive ? _buildLivingUI(baby) : _buildDeathUI(context, baby),
      ),
    );
  }

  // Wenn das Baby lebt...
  Widget _buildLivingUI(BabyController baby) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("👶", style: TextStyle(fontSize: 120)),
        const SizedBox(height: 20),
        _statusSlider("Mageninhalt (Döner)", baby.hunger, Colors.red),
        _statusSlider("Chill-Faktor (🥦)", baby.chillLevel, Colors.green),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionBtn("Döner", Icons.fastfood, Colors.orange, () => baby.feed(20)),
            _actionBtn("Joint", Icons.smoke_free, Colors.green, () => baby.smoke(25)),
          ],
        ),
      ],
    );
  }

  // Wenn das Baby tot ist... (Shot-Modus)
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
          const Text("TRINK EINEN SHOT!\nDann frag den Best-Man nach dem Code.",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 30),
          TextField(
            controller: codeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Geheimcode",
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (!baby.revive(codeController.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Falscher Code! Trink noch einen!"))
                );
              }
            },
            child: const Text("WIEDERBELEBEN"),
          ),
        ],
      ),
    );
  }

  Widget _statusSlider(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: value / 100, minHeight: 12, color: color, backgroundColor: color.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _actionBtn(String text, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
    );
  }
}§