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

  // --- DEINE NEUEN KALIBRIERUNGS-WERTE ---
  // 1. Dein gewünschter Füllstand (0.0 ist ganz unten, 1.0 ist ganz oben)
  final double _targetFillLevel = 0.69;

  // 2. Die Pixel-Grenzen für die Flasche (Hiermit löst du das Höhen-Problem!)
  // Verändere diese Werte, bis der rote Strich perfekt den sichtbaren Flaschenbauch abdeckt.
  final double _minLinePosition = -13.0;  // Wie weit nach unten geht 0.0? (z.B. der Flaschenboden)
  final double _maxLinePosition = 380.0; // Wie weit nach oben geht 1.0? (Darf nicht größer als 400 sein!)

  @override
  void initState() {
    super.initState();
    // Animation läuft wieder!
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2 Sekunden für hoch, 2 für runter
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
      // Wir speichern den ECHTEN Wert des roten Strichs im Moment des Tippens
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
      message = "Perfekt eingeschenkt!";
    } else if (accuracy > 0.6) {
      message = "Ganz okay. Baby trinkt es.";
    } else {
      message = "Katastrophe! Baby bekommt die Krise.";
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
    // Hier berechnen wir automatisch, auf welchem Pixel die Grüne Linie landen muss
    double targetPixelPos = _minLinePosition + (_targetFillLevel * (_maxLinePosition - _minLinePosition));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Gin Flasche füllen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
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
                  "Tippe zum Stoppen",
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

                      // --- DER ANIMIERTE ROTE STRICH ---
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          // Der Controller wert (0.0 bis 1.0) wird exakt in deine festgelegten Pixel umgerechnet
                          double currentRedPixelPos = _minLinePosition + (_controller.value * (_maxLinePosition - _minLinePosition));

                          return Positioned(
                            bottom: currentRedPixelPos,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: 30, // Korrektur der Höhe für perfekte Überlappung
                              child: Center(
                                child: Container(
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    boxShadow: [BoxShadow(color: Colors.red, blurRadius: 10)],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // --- DIE ZIEL-LINIE (Grün) ---
                      Positioned(
                        bottom: targetPixelPos,
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