import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';

class GrinderScreen extends StatefulWidget {
  const GrinderScreen({super.key});

  @override
  State<GrinderScreen> createState() => _GrinderScreenState();
}

class _GrinderScreenState extends State<GrinderScreen> {
  double _grindProgress = 0.0;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startGrinding();
  }

  void _startGrinding() {
    // Hört auf die Gyroskop-Werte des Handys (Rotationsgeschwindigkeit)
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (_isFinished) return;

      // Wir addieren die absoluten Rotationswerte aller Achsen.
      // So ist es egal, in welchem Winkel der Bräutigam das Handy hält - Hauptsache er dreht es!
      double movement = event.x.abs() + event.y.abs() + event.z.abs();

      // Ein kleiner Threshold, damit normale Bewegungen nicht sofort zählen
      if (movement > 2.0) {
        setState(() {
          // Multiplikator bestimmt die Schwierigkeit. 
          // Bei 0.5 muss man schon ein paar Sekunden ordentlich drehen.
          _grindProgress += movement * 0.5; 
          
          if (_grindProgress >= 100.0) {
            _grindProgress = 100.0;
            _finishGrinding();
          }
        });
      }
    });
  }

  void _finishGrinding() {
    _isFinished = true;
    _gyroSubscription?.cancel();

    // BabyController updaten (gibt 25 Chill-Punkte)
    Provider.of<BabyController>(context, listen: false).smoke(25.0);

    // Erfolgsmeldung anzeigen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🥦 Perfekt gegrindet! Chill-Level steigt!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Nach kurzer Verzögerung zurück zum Hauptbildschirm
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Dreh den Grinder!"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ein rotierendes Icon würde das Ganze noch cooler machen, 
            // aber für den Anfang reicht ein passendes Emoji.
            const Text("🔄", style: TextStyle(fontSize: 100)),
            const SizedBox(height: 30),
            const Text(
              "Bewege das Handy\nwie einen Grinder!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 24, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _grindProgress / 100,
                  minHeight: 25,
                  backgroundColor: Colors.white24,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${_grindProgress.toInt()}%",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}