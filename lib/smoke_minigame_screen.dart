import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'baby_controller.dart';

class SmokeMinigameScreen extends StatefulWidget {
  const SmokeMinigameScreen({super.key});

  @override
  State<SmokeMinigameScreen> createState() => _SmokeMinigameScreenState();
}

class _SmokeMinigameScreenState extends State<SmokeMinigameScreen> {
  // ÄNDERUNG: Wir starten direkt bei Step 2 (Gras kaufen), um den Klick zu sparen
  int step = 2;
  bool isWeedInGrinder = false;
  double grinderRotation = 0.0;
  double rollProgress = 0.0;
  StreamSubscription? _sensorSub;

  void nextStep() {
    setState(() {
      step++;
      // Wenn wir zu Step 7 kommen, Sensoren starten
      if (step == 7) {
        _startRollingSensor();
      }
    });
  }

  void _startRollingSensor() {
    _sensorSub?.cancel();
    _sensorSub = userAccelerometerEvents.listen((event) {
      if (step != 7) return;
      setState(() {
        rollProgress += (event.x.abs() + event.y.abs()) * 0.015; // Etwas schneller
        if (rollProgress >= 1.0) {
          _sensorSub?.cancel();
          nextStep();
        }
      });
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Vorbereitung - Schritt ${step - 1}")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildStepContent(baby),
        ),
      ),
    );
  }

  Widget _buildStepContent(BabyController baby) {
    switch (step) {
    // Step 1 ist weggefallen.
      case 2:
        return ElevatedButton.icon(
          onPressed: nextStep,
          icon: const Icon(Icons.shopping_cart),
          label: const Text("Gras kaufen"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), textStyle: const TextStyle(fontSize: 18)),
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Kein Geld dabei?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                baby.addDebt(50.0);
                nextStep();
              },
              icon: const Icon(Icons.money_off),
              // ÄNDERUNG: Währung auf CHF angepasst
              label: const Text("Auf Pump beim Kollegen kaufen (50 CHF)"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[300], foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            const Text("Zieh das Gras in den Grinder!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            // Die Gras-Quelle
            if (!isWeedInGrinder)
              Draggable<String>(
                data: 'weed',
                feedback: Image.asset('assets/weed.png', width: 100),
                childWhenDragging: Opacity(opacity: 0.3, child: Image.asset('assets/weed.png', width: 100)),
                child: Image.asset('assets/weed.png', width: 100),
              ),
            const SizedBox(height: 80),
            // Das Grinder-Ziel
            DragTarget<String>(
              onAccept: (data) {
                if (data == 'weed') {
                  setState(() => isWeedInGrinder = true);
                  Future.delayed(const Duration(milliseconds: 800), nextStep);
                }
              },
              builder: (context, candidateData, rejectedData) => Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: candidateData.isNotEmpty ? Colors.green[100] : Colors.transparent,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ÄNDERUNG: grinder_side.png als Zielbild
                    Image.asset('assets/grinder_side.png', width: 150),
                    if (isWeedInGrinder)
                      const Opacity(opacity: 0.8, child: Icon(Icons.check_circle, color: Colors.green, size: 80))
                  ],
                ),
              ),
            ),
          ],
        );
      case 5:
        return Column(
          children: [
            const Text("Dreh den Grinder! (Wische horizontal)", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 50),
            GestureDetector(
              onPanUpdate: (details) {
                setState(() => grinderRotation += details.delta.dx * 0.08); // Schneller
                if (grinderRotation.abs() > 30) nextStep();
              },
              child: Transform.rotate(
                angle: grinderRotation,
                child: Image.asset('assets/grinder_top.png', width: 220),
              ),
            ),
          ],
        );
      case 6:
        return ElevatedButton.icon(
          onPressed: nextStep,
          icon: const Icon(Icons.handyman),
          label: const Text("Joint bauen"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
        );
      case 7:
      // Sensor wird automatisch in nextStep gestartet.
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Schüttle das Handy heftig, um zu drehen!", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
            const SizedBox(height: 50),
            LinearProgressIndicator(value: rollProgress.clamp(0, 1), minHeight: 20, borderRadius: BorderRadius.circular(10),),
            const SizedBox(height: 20),
            // Hier ein Bild vom Bauen einfügen falls vorhanden
            Image.asset('assets/joint_unlit.png', width: 180),
          ],
        );
      case 8:
        return Column(
          children: [
            const Text("Geschafft!\nÜbergib den Joint an das Baby!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () {
                baby.smoke(35); // Etwas mehr Chill-Boost
                Navigator.pop(context);
              },
              child: Image.asset('assets/joint_lit.png', width: 250),
            ),
            const Text("\n(Tippe auf den Joint zum Inhalieren)"),
          ],
        );
      default:
        return const Text("Ein Fehler ist aufgetreten.");
    }
  }
}