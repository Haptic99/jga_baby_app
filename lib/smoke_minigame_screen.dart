import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'baby_controller.dart';
import 'package:flutter/services.dart';

// Hilfsliste für den "Text-Outline" Effekt (schwarze Ränder um weißen Text)
const List<Shadow> outlineShadows = [
  Shadow(offset: Offset(-2, -2), color: Colors.black),
  Shadow(offset: Offset(2, -2), color: Colors.black),
  Shadow(offset: Offset(-2, 2), color: Colors.black),
  Shadow(offset: Offset(2, 2), color: Colors.black),
  Shadow(offset: Offset(0, 3), color: Colors.black),
];

class SmokeMinigameScreen extends StatefulWidget {
  const SmokeMinigameScreen({super.key});

  @override
  State<SmokeMinigameScreen> createState() => _SmokeMinigameScreenState();
}

class _SmokeMinigameScreenState extends State<SmokeMinigameScreen> {
  int step = 1;
  bool isWeedInGrinder = false;
  bool babyGotJoint = false;
  double rollProgress = 0.0;
  StreamSubscription? _sensorSub;

  // --- NEUE TIMER VARIABLEN ---
  Timer? _gameTimer;
  int _timeRemaining = 35; // Zeit in Sekunden (kannst du anpassen)
  final int _totalTime = 35;
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    _startGameTimer();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _gameTimer?.cancel();
        setState(() {
          _timeUp = true; // Zeit abgelaufen
        });
      }
    });
  }

  void nextStep() {
    setState(() {
      step++;
      // Sensor startet jetzt bei Schritt 3 (Handy schütteln, um Joint zu drehen)
      if (step == 3) _startRollingSensor();
    });
  }

  void _startRollingSensor() {
    _sensorSub?.cancel();
    _sensorSub = userAccelerometerEventStream().listen((event) {
      if (step != 3) return;
      double acceleration = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > 13.0) {
        setState(() {
          rollProgress += acceleration * 0.005;
          if (rollProgress >= 1.0) {
            rollProgress = 1.0;
            _sensorSub?.cancel();
            if (step == 3) nextStep();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _gameTimer?.cancel(); // Wichtig: Timer beim Verlassen aufräumen
    super.dispose();
  }

  // --- STRAFEN DIALOG ---
  void _showPenaltyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.red, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "💀 ZEIT ABGELAUFEN!",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 24, shadows: outlineShadows),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Du warst zu langsam!\n\nTRINK EINEN SHOT\nODER ISS EIN EDIBLE!",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Dialog schließen
              Navigator.pop(context); // Minispiel verlassen -> zurück zum Homescreen
            },
            child: const Text("ERLEDIGT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyController>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark-Mode
      body: SafeArea(
        child: Column(
          children: [
            _buildTimerBar(), // Timer-Balken oben
            Expanded(child: _buildStepContent(baby)), // Hauptinhalt nimmt den restlichen Platz ein
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black54,
      child: Column(
        children: [
          Text(
            _timeUp ? "ZEIT ABGELAUFEN! STRAFE WARTET!" : "ZEIT: $_timeRemaining s",
            style: TextStyle(
              color: _timeUp ? Colors.red : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              shadows: outlineShadows,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _timeRemaining / _totalTime,
                backgroundColor: Colors.grey[800],
                color: _timeRemaining > 10 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BabyController baby) {
    switch (step) {
      case 1:
      // Chat Minigame
        return _ChatMinigame(onCompleted: nextStep);

      case 2:
      // Kombinierter Grinder-Action-Screen
        return _CombinedGrinderWorkflow(onCompleteAction: nextStep);

      case 3:
      // Joint schütteln
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/joint_mini_game_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "JOINT DREHEN",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: outlineShadows,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "SCHÜTTLE DAS HANDY KRÄFTIG",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: outlineShadows,
                  letterSpacing: 1.0,
                ),
              ),

              const Spacer(),

              Image.asset('assets/joint_unlit.png', width: 250),

              const Spacer(),

              Text(
                  "${(rollProgress.clamp(0.0, 1.0) * 100).toInt()}% GEDREHT",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    shadows: outlineShadows,
                  )
              ),
              const SizedBox(height: 8),
              Container(
                width: 250,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 3))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                      value: rollProgress.clamp(0.0, 1.0),
                      color: Colors.green,
                      backgroundColor: Colors.transparent
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );

      case 4:
      // Übergeben an Baby
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/joint_mini_game_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "JOINT ÜBERGEBEN",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: outlineShadows,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "ZIEH DEN JOINT ZUM BABY!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: outlineShadows,
                  letterSpacing: 1.0,
                ),
              ),

              const SizedBox(height: 30),

              if (!babyGotJoint)
                Draggable<String>(
                  data: 'joint',
                  feedback: Material(
                    color: Colors.transparent,
                    child: Image.asset('assets/joint_lit.png', width: 240),
                  ),
                  childWhenDragging: Opacity(opacity: 0.2, child: Image.asset('assets/joint_lit.png', width: 200)),
                  child: Image.asset('assets/joint_lit.png', width: 200),
                )
              else
                const SizedBox(height: 50),

              Expanded(
                child: Center(
                  child: DragTarget<String>(
                    onAcceptWithDetails: (details) {
                      if (details.data == 'joint') {
                        setState(() => babyGotJoint = true);
                        baby.smoke(40);

                        _gameTimer?.cancel(); // Timer stoppen, Aufgabe ist erledigt

                        // Spiel beenden und entsprechend reagieren
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (mounted) {
                            if (_timeUp) {
                              _showPenaltyDialog(); // Strafe anzeigen, falls Zeit abgelaufen
                            } else {
                              Navigator.pop(context); // Normal zurück zum Homescreen
                            }
                          }
                        });
                      }
                    },
                    builder: (context, candidateData, rejectedData) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                            'assets/baby.png',
                            height: 480,
                            fit: BoxFit.contain
                        ),
                        if (candidateData.isNotEmpty)
                          const Text(
                              "GIB MIR!",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                shadows: outlineShadows,
                              )
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      default:
        return const Center(child: Text("Fehler.", style: TextStyle(color: Colors.white)));
    }
  }
}

// ---------------------------------------------------------
// Chat Minigame Widgets (Unverändert)
// ---------------------------------------------------------

class _ChatMinigame extends StatefulWidget {
  final VoidCallback onCompleted;
  const _ChatMinigame({required this.onCompleted});

  @override
  State<_ChatMinigame> createState() => _ChatMinigameState();
}

class _ChatMinigameState extends State<_ChatMinigame> {
  int chatStage = 0;
  List<Map<String, dynamic>> messages = [];
  bool isBoroTyping = false;
  bool showNextUserInput = true;
  bool showContinueButton = false;

  String get currentInputText {
    if (chatStage == 0) return "Ehy Boro was geht, i glob i han mini sportsache no bi dir vergesse";
    if (chatStage == 1) return "Ähm glob 5 kg oder so im gsamte";
    if (chatStage == 2) return "Hüt so am 5";
    return "";
  }

  void _handleSend() async {
    if (isBoroTyping || chatStage > 2 || !showNextUserInput || showContinueButton) return;

    final userMsg = currentInputText;
    setState(() {
      messages.insert(0, {"sender": "user", "text": userMsg});
      showNextUserInput = false;
    });

    if (chatStage == 2) {
      setState(() => chatStage++);
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => showContinueButton = true);
      });
      return;
    }

    setState(() {
      isBoroTyping = true;
      chatStage++;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    String boroReply = "";
    if (chatStage == 1) boroReply = "Ehy you stimmt, wie schwer sind die nomel gsi?";
    if (chatStage == 2) boroReply = "Ah easy kein stress wenn chunsches go holle?";

    setState(() {
      isBoroTyping = false;
      messages.insert(0, {"sender": "boro", "text": boroReply});
      showNextUserInput = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayInput = (!showNextUserInput || currentInputText.isEmpty) ? "..." : currentInputText;
    bool canSend = !isBoroTyping && chatStage <= 2 && showNextUserInput && !showContinueButton;

    return Column(
      children: [
        // Fake Messenger Header
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/profil_picture.jpg'),
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Boro", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("Online", style: TextStyle(color: Colors.green[400], fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),

        // Chat Historie
        Expanded(
          child: Container(
            color: Colors.black26,
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _ChatBubble(text: msg["text"], isUser: msg["sender"] == "user");
              },
            ),
          ),
        ),

        // "Boro schreibt..." Indikator
        if (isBoroTyping)
          Container(
            color: Colors.black26,
            padding: const EdgeInsets.only(left: 20, bottom: 8, top: 4),
            alignment: Alignment.centerLeft,
            child: const Text("Boro schreibt...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ),

        // Der "Weiter" Button
        if (showContinueButton)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: widget.onCompleted,
                child: const Text("WEITER", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

        // Fake Eingabebereich
        Container(
          color: Colors.grey[850],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    displayInput,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: canSend ? Colors.green : Colors.grey[600],
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _handleSend,
                ),
              )
            ],
          ),
        ),

        // Fake Tastatur Bild
        Image.asset(
          'assets/keyboard.jpg',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: isUser ? Colors.green[600] : Colors.grey[800],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Kombinierter Grinder-Action Workflow (Fill -> Close -> Grind) (Unverändert)
// ---------------------------------------------------------

class _CombinedGrinderWorkflow extends StatefulWidget {
  final VoidCallback onCompleteAction;
  const _CombinedGrinderWorkflow({required this.onCompleteAction});

  @override
  State<_CombinedGrinderWorkflow> createState() => _CombinedGrinderWorkflowState();
}

class _CombinedGrinderWorkflowState extends State<_CombinedGrinderWorkflow> {
  int grinderSubstep = 0;
  double grinderRotation = 0.0;
  double grindProgress = 0.0;
  double lastAngle = 0.0;
  bool _isFinished = false;

  // NEU: Tracking, wann zuletzt vibriert wurde (verhindert Dauervibrieren)
  double _lastVibrationProgress = 0.0;

  final double elementSize = 234.0;

  String _getWorkflowTitle() {
    if (grinderSubstep == 0) return "GRAS IN GRINDER ZIEHEN";
    if (grinderSubstep == 1) return "DECKEL AUFSETZEN";
    return "GRINDER DREHEN";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/joint_mini_game_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _getWorkflowTitle(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: outlineShadows,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // --- OBEN: Der Deckel ---
          SizedBox(height: elementSize, child: _buildTopSlot()),
          const SizedBox(height: 20),

          // --- MITTE: Die Grinder-Unterseite ---
          SizedBox(height: elementSize, child: _buildCenterSlot()),
          const SizedBox(height: 20),

          // --- UNTEN: Das Gras ---
          SizedBox(height: elementSize, child: _buildBottomSlot()),

          const Spacer(),

          Opacity(
            opacity: grinderSubstep == 2 ? 1.0 : 0.0,
            child: Column(
              children: [
                Text(
                    "${((grindProgress / 25.0).clamp(0.0, 1.0) * 100).toInt()}% GEMAHLEN",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      shadows: outlineShadows,
                    )
                ),
                const SizedBox(height: 8),
                Container(
                  width: 250,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 3))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(
                        value: (grindProgress / 25.0).clamp(0.0, 1.0),
                        color: Colors.green,
                        backgroundColor: Colors.transparent
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSlot() {
    if (grinderSubstep == 0) {
      return Opacity(
        opacity: 0.4,
        child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize),
      );
    } else if (grinderSubstep == 1) {
      return Draggable<String>(
        data: 'lid',
        feedback: Material(
          color: Colors.transparent,
          child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize),
        ),
        childWhenDragging: Opacity(
            opacity: 0.2,
            child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize)
        ),
        child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildCenterSlot() {
    if (grinderSubstep == 0) {
      return DragTarget<String>(
        onAcceptWithDetails: (details) {
          if (details.data == 'weed') setState(() => grinderSubstep = 1);
        },
        builder: (context, candidateData, rejectedData) => Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/grinder_base_open.png', width: elementSize, height: elementSize),
            if (candidateData.isNotEmpty)
              const Icon(Icons.arrow_upward, color: Colors.green, size: 60),
          ],
        ),
      );
    } else if (grinderSubstep == 1) {
      return DragTarget<String>(
        onAcceptWithDetails: (details) {
          if (details.data == 'lid') setState(() => grinderSubstep = 2);
        },
        builder: (context, candidateData, rejectedData) => Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/grinder_base_open.png', width: elementSize, height: elementSize),
            Image.asset('assets/weed.png', width: elementSize * 0.6),
            if (candidateData.isNotEmpty)
              const Icon(Icons.arrow_downward, color: Colors.green, size: 60),
          ],
        ),
      );
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/grinder_base_open.png', width: elementSize, height: elementSize),
          GestureDetector(
            onPanUpdate: (details) {
              if (_isFinished) return;
              Offset center = Offset(elementSize / 2, elementSize / 2);
              double currentAngle = math.atan2(
                  details.localPosition.dy - center.dy,
                  details.localPosition.dx - center.dx
              );
              double diff = currentAngle - lastAngle;
              if (diff > math.pi) diff -= 2 * math.pi;
              if (diff < -math.pi) diff += 2 * math.pi;

              setState(() {
                grinderRotation += diff;
                grindProgress += diff.abs();
                lastAngle = currentAngle;
              });

              // NEU: Haptisches Feedback (löst alle ~1.0 Einheiten aus)
              if (grindProgress - _lastVibrationProgress >= 1.0) {
                HapticFeedback.selectionClick();
                _lastVibrationProgress = grindProgress;
              }

              if (grindProgress >= 25.0 && !_isFinished) {
                _isFinished = true;
                grindProgress = 25.0;
                Future.delayed(const Duration(milliseconds: 500), widget.onCompleteAction);
              }
            },
            onPanStart: (details) {
              Offset center = Offset(elementSize / 2, elementSize / 2);
              lastAngle = math.atan2(
                  details.localPosition.dy - center.dy,
                  details.localPosition.dx - center.dx
              );
            },
            child: Transform.rotate(
              angle: grinderRotation,
              child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBottomSlot() {
    if (grinderSubstep == 0) {
      return Draggable<String>(
        data: 'weed',
        feedback: Material(
          color: Colors.transparent,
          child: Image.asset('assets/weed.png', width: elementSize * 0.8),
        ),
        childWhenDragging: Opacity(
            opacity: 0.2,
            child: Image.asset('assets/weed.png', width: elementSize * 0.8)
        ),
        child: Image.asset('assets/weed.png', width: elementSize * 0.8),
      );
    } else {
      return const SizedBox();
    }
  }
}