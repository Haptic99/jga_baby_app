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
      message = "Katastrophe! Baby bekommt die Krise (Alarm-Chance extrem hoch!)";
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
      backgroundColor: Colors.indigo[900],
      appBar: AppBar(
        title: const Text("Gin Flasche füllen", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _stopGame,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Tippe auf den Bildschirm\num zu stoppen!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),

              SizedBox(
                height: 400,
                width: 150,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        border: Border.all(color: Colors.white, width: 4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    if (!_isPlaying)
                      FractionallySizedBox(
                        heightFactor: _stoppedValue,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.8),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),

                    if (_isPlaying)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Positioned(
                            bottom: _controller.value * 400,
                            left: 0,
                            right: 0,
                            // KORREKTUR: color und boxShadow in BoxDecoration verschoben!
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

                    Positioned(
                      bottom: _targetFillLevel * 400,
                      left: -20,
                      right: -20,
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Colors.greenAccent, size: 30),
                          // KORREKTUR: color und boxShadow in BoxDecoration verschoben!
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
    );
  }
}