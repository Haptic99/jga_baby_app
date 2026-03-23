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
  int step = 2;
  bool isWeedInGrinder = false;
  bool babyGotJoint = false;
  double grinderRotation = 0.0;
  double lastAngle = 0.0;
  double rollProgress = 0.0;
  StreamSubscription? _sensorSub;

  void nextStep() {
    setState(() {
      step++;
      if (step == 7) _startRollingSensor();
    });
  }

  void _startRollingSensor() {
    _sensorSub?.cancel();
    _sensorSub = userAccelerometerEvents.listen((event) {
      if (step != 7) return;
      setState(() {
        rollProgress += (event.x.abs() + event.y.abs()) * 0.02;
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildStepContent(baby),
      ),
    );
  }

  Widget _buildStepContent(BabyController baby) {
    switch (step) {
      case 2:
        return Center(child: ElevatedButton.icon(
          onPressed: nextStep, icon: const Icon(Icons.shopping_cart),
          label: const Text("Gras kaufen"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
        ));
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      case 4:
        return Column(
          children: [
            const Text("Zieh das Gras in den Grinder!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (!isWeedInGrinder)
              Draggable<String>(
                data: 'weed',
                feedback: Image.asset('assets/weed.png', width: 120), // 20% Grösser
                childWhenDragging: Opacity(opacity: 0.3, child: Image.asset('assets/weed.png', width: 120)),
                child: Image.asset('assets/weed.png', width: 120),
              ),
            const SizedBox(height: 50),
            DragTarget<String>(
              onAccept: (data) {
                if (data == 'weed') {
                  setState(() => isWeedInGrinder = true);
                  Future.delayed(const Duration(milliseconds: 800), nextStep);
                }
              },
              builder: (context, candidateData, rejectedData) => Container(
                width: 250, height: 250,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/grinder_side.png', width: 210), // 30% Grösser
                    if (isWeedInGrinder) const Icon(Icons.check_circle, color: Colors.green, size: 100)
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Dreh den Grinder im Kreis!", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Berechnung der kreisförmigen Drehung
                  Offset center = const Offset(150, 150); // Annahme Mitte des Widgets
                  double currentAngle = math.atan2(details.localPosition.dy - center.dy, details.localPosition.dx - center.dx);
                  setState(() {
                    grinderRotation += (currentAngle - lastAngle).clamp(-0.5, 0.5);
                    lastAngle = currentAngle;
                  });
                  if (grinderRotation.abs() > 15) nextStep();
                },
                onPanStart: (details) {
                  Offset center = const Offset(150, 150);
                  lastAngle = math.atan2(details.localPosition.dy - center.dy, details.localPosition.dx - center.dx);
                },
                child: Transform.rotate(
                  angle: grinderRotation,
                  child: Image.asset('assets/grinder_top.png', width: 280), // 30% Grösser
                ),
              ),
            ),
          ],
        );
      case 6:
        return Center(child: ElevatedButton.icon(
          onPressed: nextStep, icon: const Icon(Icons.handyman),
          label: const Text("Joint bauen"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
        ));
      case 7:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Schüttle das Handy!", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            LinearProgressIndicator(value: rollProgress.clamp(0, 1), minHeight: 20, borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 30),
            Image.asset('assets/joint_unlit.png', width: 220),
          ],
        );
      case 8:
        return Column(
          children: [
            const Text("Zieh den Joint zum Baby!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (!babyGotJoint)
              Draggable<String>(
                data: 'joint',
                feedback: Image.asset('assets/joint_lit.png', width: 200),
                childWhenDragging: Opacity(opacity: 0.3, child: Image.asset('assets/joint_lit.png', width: 200)),
                child: Image.asset('assets/joint_lit.png', width: 200),
              ),
            const SizedBox(height: 60),
            DragTarget<String>(
              onAccept: (data) {
                if (data == 'joint') {
                  setState(() => babyGotJoint = true);
                  baby.smoke(40);
                  Future.delayed(const Duration(milliseconds: 1000), () => Navigator.pop(context));
                }
              },
              builder: (context, candidateData, rejectedData) => Column(
                children: [
                  const Text("👶", style: TextStyle(fontSize: 120)),
                  if (candidateData.isNotEmpty) const Text("HUNGRIG!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                ],
              ),
            ),
            const Spacer(),
          ],
        );
      default:
        return const Center(child: Text("Fehler."));
    }
  }
}