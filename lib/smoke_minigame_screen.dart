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
  double grinderRotation = 0.0;
  double rollProgress = 0.0;
  StreamSubscription? _sensorSub;

  void nextStep() => setState(() => step++);

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Step $step: Joint Vorbereitung")),
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
        return ElevatedButton(onPressed: nextStep, child: const Text("Joint rauchen"));
      case 2:
        return ElevatedButton(onPressed: nextStep, child: const Text("Gras kaufen"));
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Kein Geld dabei?", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                baby.addDebt(50.0);
                nextStep();
              },
              child: const Text("Auf Pump beim Kollegen kaufen (50€)"),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            const Text("Zieh das Gras in den Grinder!"),
            const SizedBox(height: 50),
            if (!isWeedInGrinder)
              Draggable<String>(
                data: 'weed',
                feedback: Image.asset('assets/weed.png', width: 80),
                childWhenDragging: Container(),
                child: Image.asset('assets/weed.png', width: 80),
              ),
            const SizedBox(height: 100),
            DragTarget<String>(
              onAccept: (data) {
                setState(() => isWeedInGrinder = true);
                Future.delayed(const Duration(seconds: 1), nextStep);
              },
              builder: (context, candidateData, rejectedData) => Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  shape: BoxShape.circle,
                ),
                child: isWeedInGrinder
                    ? const Icon(Icons.check, color: Colors.green, size: 50)
                    : const Center(child: Text("GRINDER")),
              ),
            ),
          ],
        );
      case 5:
        return Column(
          children: [
            const Text("Dreh den Grinder! (Wische im Kreis)"),
            const SizedBox(height: 50),
            GestureDetector(
              onPanUpdate: (details) {
                setState(() => grinderRotation += details.delta.dx * 0.05);
                if (grinderRotation.abs() > 20) nextStep();
              },
              child: Transform.rotate(
                angle: grinderRotation,
                child: Image.asset('assets/grinder_top.png', width: 200),
              ),
            ),
          ],
        );
      case 6:
        return ElevatedButton(onPressed: nextStep, child: const Text("Joint bauen"));
      case 7:
        if (_sensorSub == null) {
          _sensorSub = userAccelerometerEvents.listen((event) {
            setState(() {
              rollProgress += (event.x.abs() + event.y.abs()) * 0.01;
              if (rollProgress >= 1.0) {
                _sensorSub?.cancel();
                nextStep();
              }
            });
          });
        }
        return Column(
          children: [
            const Text("Schüttle das Handy, um zu drehen!"),
            const SizedBox(height: 50),
            LinearProgressIndicator(value: rollProgress.clamp(0, 1)),
            const SizedBox(height: 20),
            Image.asset('assets/joint_unlit.png', width: 150),
          ],
        );
      case 8:
        return Column(
          children: [
            const Text("Anrauchen und dem Baby geben!"),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () {
                baby.smoke(30);
                Navigator.pop(context); // Zurück zum Hauptscreen
              },
              child: Image.asset('assets/joint_lit.png', width: 200),
            ),
            const Text("\n(Tippe auf den Joint zum Inhalieren)"),
          ],
        );
      default:
        return Container();
    }
  }
}