import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';

class GinMinigameScreen extends StatefulWidget {
  const GinMinigameScreen({super.key});

  @override
  State<GinMinigameScreen> createState() => _GinMinigameScreenState();
}

class _GinMinigameScreenState extends State<GinMinigameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;
  double _stoppedValue = 0.0;

  // --- HIER IST DEIN KALIBRIERUNGS-WERT (0.58) ---
  final double _targetFillLevel = 0.58;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Langsame Geschwindigkeit belassen, egal da keine Animation
    );
    // ..repeat(reverse: true); // --- TEST-MODUS: ANIMATION AUSGESCHALTET ---
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stopGame() {
    if (!_isPlaying) return;

    // _controller.stop(); // --- TEST-MODUS: Controller läuft eh nicht ---
    setState(() {
      _isPlaying = false;
      // --- TEST-MODUS: Wir zwingen die Logik auf den perfekten Wert ---
      _stoppedValue = _targetFillLevel;
    });

    double difference = (_targetFillLevel - _stoppedValue).abs();

    double maxError = _targetFillLevel > (1 - _targetFillLevel) ? _targetFillLevel : (1 - _targetFillLevel);
    double accuracy = (1.0 - (difference / maxError)).clamp(0.0, 1.0);

    Provider.of<BabyController>(context, listen: false).evaluateGinFilling(accuracy);

    _showResultDialog(accuracy);
  }

  void _showResultDialog(double accuracy) {
    String message = "";
    if (accuracy > 0.9) {
      message = "Perfekt eingeschenkt! (TESTMODUS)";
    } else if (accuracy > 0.6) {
      message = "Ganz okay. Baby trinkt es.";
    } else {
      message = "Katastrophe! Baby bekommt die Krise.";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Ergebnis (TESTMODUS)"),
        content: Text("Genauigkeit: ${(accuracy * 100).toInt()}%\n\n$message\n\nVisueller Wert: $_targetFillLevel\nLogischer Wert: $_stoppedValue"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Zurück zum Baby"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Gin Flasche füllen [TEST]", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/gin_baby_bottle_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _stopGame,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "[TESTMODUS]\nTippe zum Stoppen",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2))]
                  ),
                ),
                const SizedBox(height: 50),

                SizedBox(
                  height: 400,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // --- DAS FLASCHEN BILD ---
                      Positioned.fill(
                        child: Image.asset(
                          'assets/gin_baby_bottle.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // --- DER RASENDE STRICH (JETZT STATISCH) ---
                      // Wir rendern nur einen statischen Strich, der genau wie der grüne berechnet wird.
                      // if (_isPlaying) AnimatedBuilder... wurde entfernt

                      // Statischer Roter Strich an der Zielposition (nutzt 442 Multiplikator wie grün)
                      Positioned(
                        bottom: _targetFillLevel * 442,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [BoxShadow(color: Colors.red, blurRadius: 10)],
                          ),
                        ),
                      ),

                      // --- DIE ZIEL-LINIE (Bester Füllstand) ---
                      Positioned(
                        bottom: _targetFillLevel * 442, // Beibehaltung des 442 Multiplikators
                        left: -20,
                        right: -20,
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right, color: Colors.greenAccent, size: 30),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  boxShadow: [BoxShadow(color: Colors.green, blurRadius: 8)],
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_left, color: Colors.greenAccent, size: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}