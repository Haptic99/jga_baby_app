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

  final double _targetFillLevel = 0.8;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stopGame() {
    if (!_isPlaying) return;

    _controller.stop();
    setState(() {
      _isPlaying = false;
      _stoppedValue = _controller.value;
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
      message = "Perfekt eingeschenkt! Baby ist beruhigt.";
    } else if (accuracy > 0.6) {
      message = "Ganz okay. Baby trinkt es.";
    } else {
      message = "Katastrophe! Baby bekommt die Krise (Alarm-Chance hoch!)";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Ergebnis"),
        content: Text("Genauigkeit: ${(accuracy * 100).toInt()}%\n\n$message"),
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
      extendBodyBehindAppBar: true, // Lässt den Hintergrund hinter die AppBar gehen
      appBar: AppBar(
        title: const Text("Gin Flasche füllen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // --- NEUES HINTERGRUNDBILD FÜR DEN SCREEN ---
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
                  "Tippe auf den Bildschirm\num zu stoppen!",
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
                  width: 200, // Etwas breiter gemacht, damit die Flasche gut reinpasst
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // --- DIE FLÜSSIGKEIT (Liegt HINTER der Flasche) ---
                      if (!_isPlaying)
                        FractionallySizedBox(
                          heightFactor: _stoppedValue,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.6), // Leicht bläuliche Gin-Farbe
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                          ),
                        ),

                      // --- DAS NEUE FLASCHEN BILD ---
                      Positioned.fill(
                        child: Image.asset(
                          'assets/gin_baby_bottle.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // --- DER RASENDE STRICH ---
                      if (_isPlaying)
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Positioned(
                              bottom: _controller.value * 400,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  boxShadow: [BoxShadow(color: Colors.red, blurRadius: 10)],
                                ),
                              ),
                            );
                          },
                        ),

                      // --- DIE ZIEL-LINIE (Bester Füllstand) ---
                      Positioned(
                        bottom: _targetFillLevel * 320,
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