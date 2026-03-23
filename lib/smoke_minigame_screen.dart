import 'dart:async';
import 'dart:math' as math;
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
  int step = 1;
  bool isWeedInGrinder = false;
  bool babyGotJoint = false;
  double grinderRotation = 0.0;
  double grindProgress = 0.0; // NEU: Separater Fortschritt für den Grinder
  double lastAngle = 0.0;
  double rollProgress = 0.0;
  StreamSubscription? _sensorSub;

  void nextStep() {
    setState(() {
      step++;
      if (step == 6) _startRollingSensor();
    });
  }

  void _startRollingSensor() {
    _sensorSub?.cancel();
    _sensorSub = userAccelerometerEvents.listen((event) {
      if (step != 6) return;
      double acceleration = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > 13.0) {
        setState(() {
          rollProgress += acceleration * 0.005;
          if (rollProgress >= 1.0) {
            _sensorSub?.cancel();
            nextStep();
          }
        });
      }
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
      appBar: AppBar(title: Text("Vorbereitung - Schritt $step / 7")),
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
      case 1:
        return ElevatedButton.icon(
          onPressed: nextStep, icon: const Icon(Icons.shopping_cart),
          label: const Text("Gras kaufen"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), textStyle: const TextStyle(fontSize: 18)),
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Kein Geld dabei?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () { baby.addDebt(50.0); nextStep(); },
              icon: const Icon(Icons.money_off),
              label: const Text("Auf Pump beim Kollegen kaufen (50 CHF)"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[300], foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Zieh das Gras in den Grinder!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            if (!isWeedInGrinder)
              Draggable<String>(
                data: 'weed',
                feedback: Image.asset('assets/weed.png', width: 144),
                childWhenDragging: Opacity(opacity: 0.3, child: Image.asset('assets/weed.png', width: 120)),
                child: Image.asset('assets/weed.png', width: 120),
              )
            else
              const SizedBox(height: 120),
            const SizedBox(height: 50),
            DragTarget<String>(
              onAccept: (data) {
                if (data == 'weed') {
                  setState(() => isWeedInGrinder = true);
                  Future.delayed(const Duration(milliseconds: 800), nextStep);
                }
              },
              builder: (context, candidateData, rejectedData) => Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/grinder_side.png', width: 208),
                  if (isWeedInGrinder) const Icon(Icons.check_circle, color: Colors.green, size: 100)
                ],
              ),
            ),
          ],
        );
      case 4:
      // NEU: Fortschritt wird unabhängig von der Richtung berechnet
        double progressPercent = (grindProgress / 25.0).clamp(0.0, 1.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Dreh den Grinder im Kreis!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: progressPercent, minHeight: 10, color: Colors.green),
            const SizedBox(height: 40),
            GestureDetector(
              onPanUpdate: (details) {
                Offset center = const Offset(143, 143);
                double currentAngle = math.atan2(details.localPosition.dy - center.dy, details.localPosition.dx - center.dx);

                double diff = currentAngle - lastAngle;
                // Normalisierung bei Sprung von -PI zu PI
                if (diff > math.pi) diff -= 2 * math.pi;
                if (diff < -math.pi) diff += 2 * math.pi;

                setState(() {
                  grinderRotation += diff;
                  grindProgress += diff.abs(); // Jede Bewegung zählt!
                  lastAngle = currentAngle;
                });

                if (grindProgress > 25.0) nextStep();
              },
              onPanStart: (details) {
                Offset center = const Offset(143, 143);
                lastAngle = math.atan2(details.localPosition.dy - center.dy, details.localPosition.dx - center.dx);
              },
              child: Transform.rotate(
                angle: grinderRotation,
                child: Image.asset('assets/grinder_top.png', width: 286),
              ),
            ),
          ],
        );
      case 5:
        return ElevatedButton.icon(
          onPressed: nextStep, icon: const Icon(Icons.handyman),
          label: const Text("Joint bauen"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
        );
      case 6:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Drehe nun den Joint!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Schüttle das Handy kräftig", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            LinearProgressIndicator(value: rollProgress.clamp(0, 1), minHeight: 25, borderRadius: BorderRadius.circular(15)),
            const SizedBox(height: 40),
            Image.asset('assets/joint_unlit.png', width: 220),
          ],
        );
      case 7:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Zieh den Joint zum Baby!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            if (!babyGotJoint)
              Draggable<String>(
                data: 'joint',
                feedback: Image.asset('assets/joint_lit.png', width: 240),
                childWhenDragging: Opacity(opacity: 0.2, child: Image.asset('assets/joint_lit.png', width: 200)),
                child: Image.asset('assets/joint_lit.png', width: 200),
              )
            else
              const SizedBox(height: 200),
            const SizedBox(height: 50),
            DragTarget<String>(
              onAccept: (data) {
                if (data == 'joint') {
                  setState(() => babyGotJoint = true);
                  baby.smoke(40);
                  Future.delayed(const Duration(milliseconds: 1200), () => Navigator.pop(context));
                }
              },
              builder: (context, candidateData, rejectedData) => Column(
                children: [
                  // NEU: Hier wird das baby.png angezeigt
                  Image.asset('assets/baby.png', height: 200, fit: BoxFit.contain),
                  if (candidateData.isNotEmpty) const Text("GIB MIR!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20))
                ],
              ),
            ),
          ],
        );
      default:
        return const Text("Fehler.");
    }
  }
}