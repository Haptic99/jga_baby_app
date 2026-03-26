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
  // Das Spiel hat nun insgesamt 4 Hauptschritte: Chat(1), Grinden(2), Bauen(3), Übergeben(4).
  int step = 1;
  bool isWeedInGrinder = false; // Wird intern im GrinderWorkflow gesetzt
  bool babyGotJoint = false;
  double rollProgress = 0.0;
  StreamSubscription? _sensorSub;

  void nextStep() {
    setState(() {
      step++;
      // Sensor startet jetzt bei Schritt 3 (Handy schütteln, um Joint zu drehen)
      if (step == 3) _startRollingSensor();
    });
  }

  void _startRollingSensor() {
    _sensorSub?.cancel();
    _sensorSub = userAccelerometerEvents.listen((event) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyController>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark-Mode
      appBar: AppBar(
        // Angepasst auf 4 Gesamtschritte
        title: Text("Vorbereitung - Schritt $step / 4"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      // Bei Schritt 1 (Chat) nehmen wir die Padding-Ränder weg, damit es wie eine echte App aussieht
      body: step == 1
          ? _buildStepContent(baby)
          : Center(
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
      // Chat Minigame mit "Weiter" Button
        return _ChatMinigame(onCompleted: nextStep);

      case 2:
      // Kombinierter Grinder-Action-Screen ( Fill -> Close -> Grind )
        return _CombinedGrinderWorkflow(onCompleteAction: nextStep);

      case 3:
      // Ehemals Schritt 4 (Joint schütteln)
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Drehe nun den Joint!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Schüttle das Handy kräftig", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            LinearProgressIndicator(value: rollProgress.clamp(0, 1), minHeight: 25, borderRadius: BorderRadius.circular(15), color: Colors.green, backgroundColor: Colors.white24),
            const SizedBox(height: 40),
            Image.asset('assets/joint_unlit.png', width: 220),
          ],
        );

      case 4:
      // Ehemals Schritt 5 (Übergeben an Baby)
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Zieh den Joint zum Baby!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  // Spiel beenden und zurück zum Homescreen
                  Future.delayed(const Duration(milliseconds: 1200), () => Navigator.pop(context));
                }
              },
              builder: (context, candidateData, rejectedData) => Column(
                children: [
                  Image.asset('assets/baby.png', height: 200, fit: BoxFit.contain),
                  if (candidateData.isNotEmpty) const Text("GIB MIR!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20))
                ],
              ),
            ),
          ],
        );
      default:
        return const Text("Fehler.", style: TextStyle(color: Colors.white));
    }
  }
}

// ---------------------------------------------------------
// Chat Minigame Widgets
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
    // Senden nur erlauben, wenn Boro nicht schreibt, Text bereitsteht und der Weiter-Button noch nicht da ist
    if (isBoroTyping || chatStage > 2 || !showNextUserInput || showContinueButton) return;

    // 1. User Nachricht in den Chat einfügen
    final userMsg = currentInputText;
    setState(() {
      messages.insert(0, {"sender": "user", "text": userMsg});
      showNextUserInput = false;
    });

    // Wenn es die letzte Nachricht war, beenden wir den Sende-Workflow hier
    // und blenden nach einer kurzen Verzögerung den "Weiter"-Button ein.
    if (chatStage == 2) {
      setState(() => chatStage++);
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() => showContinueButton = true);
      });
      return;
    }

    // 2. "Boro schreibt..." aktivieren und Phase intern hochzählen
    setState(() {
      isBoroTyping = true;
      chatStage++;
    });

    // 3. Warten (Delay 1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 4. Boros Antwort generieren
    String boroReply = "";
    if (chatStage == 1) boroReply = "Ehy you stimmt, wie schwer sind die nomel gsi?";
    if (chatStage == 2) boroReply = "Ah easy kein stress wenn chunsches go holle?";

    // 5. Boros Antwort einfügen und User-Input wieder freischalten
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
              const Text("Boro", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),

        // Chat Historie
        Expanded(
          child: Container(
            color: Colors.black26,
            child: ListView.builder(
              reverse: true, // Unten anfangen
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

        // Der "Weiter" Button erscheint hier, wenn der Chat zu Ende ist
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

// Widget für eine einzelne animierte Chat-Bubble
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
// Kombinierter Grinder-Action Workflow (Fill -> Close -> Grind)
// ALLES AUF EINEM SCREEN OHNE LAYOUT-SPRÜNGE
// ---------------------------------------------------------

class _CombinedGrinderWorkflow extends StatefulWidget {
  final VoidCallback onCompleteAction;
  const _CombinedGrinderWorkflow({required this.onCompleteAction});

  @override
  State<_CombinedGrinderWorkflow> createState() => _CombinedGrinderWorkflowState();
}

class _CombinedGrinderWorkflowState extends State<_CombinedGrinderWorkflow> {
  // 0 = Gras in Grinder ziehen, 1 = Deckel auf Grinder ziehen, 2 = Mahlen
  int grinderSubstep = 0;

  double grinderRotation = 0.0;
  double grindProgress = 0.0;
  double lastAngle = 0.0;

  // Einheitliche feste Größe für Grinder-Top und Grinder-Base
  final double elementSize = 180.0;

  String _getWorkflowTitle() {
    if (grinderSubstep == 0) return "SCHRITT 2/4:\nGRAS IN DEN GRINDER FÜLLEN";
    if (grinderSubstep == 1) return "SCHRITT 2/4:\nDECKEL AUFSETZEN";
    return "SCHRITT 2/4:\nGRINDER DREHEN";
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Header Text
          Text(
            _getWorkflowTitle(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Fortschrittsbalken (nur beim Drehen sichtbar, sonst unsichtbar aber Platzhalter)
          Opacity(
            opacity: grinderSubstep == 2 ? 1.0 : 0.0,
            child: Column(
              children: [
                LinearProgressIndicator(
                    value: (grindProgress / 25.0).clamp(0.0, 1.0),
                    minHeight: 10,
                    color: Colors.green,
                    backgroundColor: Colors.white24
                ),
                const SizedBox(height: 5),
                Text(
                    "${((grindProgress / 25.0).clamp(0.0, 1.0) * 100).toInt()}% gemahlen",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),

          const Spacer(),

          // --- OBEN: Der Deckel ---
          SizedBox(
            height: elementSize,
            child: _buildTopSlot(),
          ),

          const SizedBox(height: 20),

          // --- MITTE: Die Grinder-Unterseite ---
          SizedBox(
            height: elementSize,
            child: _buildCenterSlot(),
          ),

          const SizedBox(height: 20),

          // --- UNTEN: Das Gras ---
          SizedBox(
            height: elementSize,
            child: _buildBottomSlot(),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTopSlot() {
    if (grinderSubstep == 0) {
      // Phase 0: Deckel ist sichtbar, aber ausgegraut/halbtransparent, da man erst das Gras einfüllen muss
      return Opacity(
        opacity: 0.4,
        child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize),
      );
    } else if (grinderSubstep == 1) {
      // Phase 1: Deckel kann nun auf die Base gezogen werden
      return Draggable<String>(
        data: 'lid',
        feedback: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize),
        childWhenDragging: Opacity(
            opacity: 0.2,
            child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize)
        ),
        child: Image.asset('assets/grinder_top.png', width: elementSize, height: elementSize),
      );
    } else {
      // Phase 2: Deckel ist in der Mitte auf dem Grinder, hier oben ist nun leer
      return const SizedBox();
    }
  }

  Widget _buildCenterSlot() {
    if (grinderSubstep == 0) {
      // Phase 0: Base wartet auf Gras von unten
      return DragTarget<String>(
        onAccept: (data) {
          if (data == 'weed') setState(() => grinderSubstep = 1);
        },
        builder: (context, candidateData, rejectedData) => Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/grinder_base_open.png', width: elementSize, height: elementSize),
            if (candidateData.isNotEmpty)
              const Icon(Icons.arrow_upward, color: Colors.green, size: 60), // Zeigt an, dass es hier rein soll
          ],
        ),
      );
    } else if (grinderSubstep == 1) {
      // Phase 1: Base hat Gras drin und wartet auf Deckel von oben
      return DragTarget<String>(
        onAccept: (data) {
          if (data == 'lid') setState(() => grinderSubstep = 2);
        },
        builder: (context, candidateData, rejectedData) => Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/grinder_base_open.png', width: elementSize, height: elementSize),
            // Kleines Gras in der Base anzeigen, damit man sieht, es ist drin
            Image.asset('assets/weed.png', width: elementSize * 0.6),
            if (candidateData.isNotEmpty)
              const Icon(Icons.arrow_downward, color: Colors.green, size: 60),
          ],
        ),
      );
    } else {
      // Phase 2: Deckel ist auf der Base, wir können drehen! Alles bleibt in der Mitte.
      return Stack(
        alignment: Alignment.center,
        children: [
          // Base unten
          Image.asset('assets/grinder_base_open.png', width: elementSize, height: elementSize),
          // Rotierender Deckel oben drauf
          GestureDetector(
            onPanUpdate: (details) {
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

              if (grindProgress > 25.0) {
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
      // Phase 0: Gras ist unten und kann hochgezogen werden
      return Draggable<String>(
        data: 'weed',
        feedback: Image.asset('assets/weed.png', width: elementSize * 0.8),
        childWhenDragging: Opacity(
            opacity: 0.2,
            child: Image.asset('assets/weed.png', width: elementSize * 0.8)
        ),
        child: Image.asset('assets/weed.png', width: elementSize * 0.8),
      );
    } else {
      // Phase 1 & 2: Gras wurde bereits hochgezogen, dieser Platz ist nun leer
      return const SizedBox();
    }
  }
}