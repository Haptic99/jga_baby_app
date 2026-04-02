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
  bool _isInitialized = false;
  bool _isShowingTutorial = false; // NEU: Steuert, ob das Tutorial sichtbar ist

  // --- DEINE NEUEN KALIBRIERUNGS-WERTE ---
  // 1. Dein gewünschter Füllstand (0.0 ist ganz unten, 1.0 ist ganz oben)
  final double _targetFillLevel = 0.69;

  // 2. Die Pixel-Grenzen für die Flasche (Hiermit löst du das Höhen-Problem!)
  final double _minLinePosition = -13.0;  // Wie weit nach unten geht 0.0? (z.B. der Flaschenboden)
  final double _maxLinePosition = 380.0; // Wie weit nach oben geht 1.0? (Darf nicht größer als 400 sein!)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Wir initialisieren den Controller hier, damit wir den Provider sicher auslesen können
    if (!_isInitialized) {
      final babyController = Provider.of<BabyController>(context, listen: false);
      double stress = babyController.babyStress; // Wert von 0.0 bis 100.0

      // Je höher der Stress, desto langsamer (einfacher) die Animation
      // Stress 0 -> 1000 ms (schnell, schwer)
      // Stress 100 -> 3000 ms (langsam, leicht)
      int durationMs = 1000 + (stress * 20).toInt();

      _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durationMs),
      );

      // NEU: Wenn das Tutorial noch nicht gesehen wurde, pausieren wir das Spiel.
      if (!babyController.hasSeenGinTutorial) {
        _isShowingTutorial = true;
      } else {
        _controller.repeat(reverse: true);
      }

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stopGame() {
    if (!_isPlaying || _isShowingTutorial) return;

    _controller.stop();

    setState(() {
      _isPlaying = false;
      // Wir speichern den ECHTEN Wert des roten Strichs im Moment des Tippens
      _stoppedValue = _controller.value;
    });

    // --- NEUE BERECHNUNG: 0% bei ganz oben (1.0) und ganz unten (0.0) ---
    double difference = (_targetFillLevel - _stoppedValue).abs();

    // Wir berechnen den maximal möglichen Fehler je nachdem, auf welcher Seite vom Ziel wir gelandet sind
    double maxPossibleError = _stoppedValue > _targetFillLevel
        ? (1.0 - _targetFillLevel) // Abstand vom Ziel bis zum absoluten Top
        : _targetFillLevel;        // Abstand vom Ziel bis zum absoluten Boden

    double accuracy = (1.0 - (difference / maxPossibleError)).clamp(0.0, 1.0);

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
              Navigator.pop(context); // Schließt den Dialog
              Navigator.pop(context); // Schließt den Minigame-Screen
            },
            child: const Text("Zurück zum Baby"),
          )
        ],
      ),
    );
  }

  // --- NEU: Baut das Tutorial-Overlay ---
  Widget _buildTutorialOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85), // Verdunkelt den Hintergrund
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🍾 GIN EINKSCHENKEN 🍼",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              const Text(
                "Drücke im perfekten Moment auf STOPP, um die Flasche exakt bis zur grünen Markierung zu füllen!\n\nAber Vorsicht: Je ungenauer du einschenkst, desto gestresster wird das Baby – und desto schneller fängt es wieder an zu schreien!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Tutorial abhaken und Spiel starten!
                  Provider.of<BabyController>(context, listen: false).markGinTutorialAsSeen();
                  setState(() {
                    _isShowingTutorial = false;
                  });
                  _controller.repeat(reverse: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                child: const Text(
                  "LOS GEHT'S!",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
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
        automaticallyImplyLeading: false, // <-- ENTFERNT DEN ZURÜCK-BUTTON OBEN LINKS
        title: const Text("Gin Flasche füllen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // --- DAS EIGENTLICHE SPIEL ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/gin_baby_bottle_background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Fülle den Gin bis zur Markierung!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2))]
                    ),
                  ),
                  const SizedBox(height: 30),

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

                  const SizedBox(height: 50),

                  // --- NEUER STOPP-BUTTON ---
                  ElevatedButton(
                    onPressed: _isPlaying ? _stopGame : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      "STOPP",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- NEU: TUTORIAL OVERLAY WIRD OBEN DRÜBER GELEGT, WENN NÖTIG ---
          if (_isShowingTutorial) _buildTutorialOverlay(),
        ],
      ),
    );
  }
}