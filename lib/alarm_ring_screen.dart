import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';
import 'gin_minigame_screen.dart'; // NEU: Gin-Minispiel importieren

class AlarmRingScreen extends StatelessWidget {
  const AlarmRingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.yellow),
              const SizedBox(height: 20),
              const Text(
                "WAAAH!\nBABY BORO SCHREIT!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Beruhige es, bevor die Leute schauen!",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  // Alarm stoppen
                  Provider.of<BabyController>(context, listen: false).stopAlarm();

                  // Direkt weiterleiten ins Gin-Minispiel!
                  // PushReplacement sorgt dafür, dass er mit einem Zurück-Wischen nicht hierher zurückkommt.
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const GinMinigameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "ALARM STOPPEN",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}