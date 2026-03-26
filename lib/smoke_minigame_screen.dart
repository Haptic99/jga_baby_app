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
  int step = 1; // Jetzt 5 Schritte insgesamt
  bool isWeedInGrinder = false;
  bool babyGotJoint = false;
  double grinderRotation = 0.0;
  double grindProgress = 0.0;
  double lastAngle = 0.0;
  double rollProgress = 0.0;
  StreamSubscription? _sensorSub;

  void nextStep() {
    setState(() {
      step++;
      // Sensor startet jetzt bei Schritt 4 (Handy schütteln, um Joint zu drehen)
      if (step == 4) _startRollingSensor();
    });
  }

  void _startRollingSensor() {
    _sensorSub?.cancel();
    _sensorSub = userAccelerometerEvents.listen((event) {
      if (step != 4) return;
      double acceleration = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > 13.0) {
        setState(() {
          rollProgress += acceleration * 0.005;
          if (rollProgress >= 1.0) {
            rollProgress = 1.0;
            _sensorSub?.cancel();
            if (step == 4) nextStep();
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
      backgroundColor: Colors.grey[900], // Passender Dark-Mode Style
      appBar: AppBar(
        title: Text("Vorbereitung - Schritt $step / 5"),
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
      // NEU: Chat Minigame als erster Screen
        return _ChatMinigame(onCompleted: nextStep);

      case 2:
      // Ehemals Schritt 3
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Zieh das Gras in den Grinder!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 50),
            if (!isWeedInGrinder)
              Draggable<String>(
                data: 'weed',
                feedback: Image.asset('assets/weed.png', width: 144),
                childWhenDragging: Opacity(opacity: 0.3, child: Image.asset('assets/weed.png', width: 120)),
                child: Image.asset('assets/weed.png', width: 120),
              )
            else
              const SizedBox(height: 120),
            const SizedBox(height: 50),
            DragTarget<String>(
              onAccept: (data) {
                if (data == 'weed') {
                  setState(() => isWeedInGrinder = true);
                  Future.delayed(const Duration(milliseconds: 800), nextStep);
                }
              },
              builder: (context, candidateData, rejectedData) => Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/grinder_side.png', width: 208),
                  if (isWeedInGrinder) const Icon(Icons.check_circle, color: Colors.green, size: 100)
                ],
              ),
            ),
          ],
        );

      case 3:
      // Ehemals Schritt 4
        double progressPercent = (grindProgress / 25.0).clamp(0.0, 1.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Dreh den Grinder im Kreis!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: progressPercent, minHeight: 10, color: Colors.green, backgroundColor: Colors.white24),
            const SizedBox(height: 40),
            GestureDetector(
              onPanUpdate: (details) {
                Offset center = const Offset(143, 143);
                double currentAngle = math.atan2(details.localPosition.dy - center.dy, details.localPosition.dx - center.dx);

                double diff = currentAngle - lastAngle;
                if (diff > math.pi) diff -= 2 * math.pi;
                if (diff < -math.pi) diff += 2 * math.pi;

                setState(() {
                  grinderRotation += diff;
                  grindProgress += diff.abs();
                  lastAngle = currentAngle;
                });

                // Hier auf step == 3 angepasst!
                if (step == 3 && grindProgress > 25.0) {
                  nextStep();
                }
              },
              onPanStart: (details) {
                Offset center = const Offset(143, 143);
                lastAngle = math.atan2(details.localPosition.dy - center.dy, details.localPosition.dx - center.dx);
              },
              child: Transform.rotate(
                angle: grinderRotation,
                child: Image.asset('assets/grinder_top.png', width: 286),
              ),
            ),
          ],
        );

      case 4:
      // Ehemals Schritt 5
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

      case 5:
      // Ehemals Schritt 6
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
// NEU: Chat Minigame Widgets
// ---------------------------------------------------------

class _ChatMinigame extends StatefulWidget {
  final VoidCallback onCompleted;
  const _ChatMinigame({required this.onCompleted});

  @override
  State<_ChatMinigame> createState() => _ChatMinigameState();
}

class _ChatMinigameState extends State<_ChatMinigame> {
  int chatStage = 0; // Geht von 0 bis 2 (für die 3 Phasen)
  List<Map<String, dynamic>> messages = [];
  bool isBoroTyping = false;
  // ANPASSUNG: Steuert, ob der nächste vordefinierte Text im Eingabefeld sichtbar ist
  bool showNextUserInput = true;

  String get currentInputText {
    if (chatStage == 0) return "Ehy Boro was geht, i glob i han mini sportsache no bi dir vergesse";
    if (chatStage == 1) return "Ähm glob 5 kg oder so im gsamte";
    if (chatStage == 2) return "Hüt so am 5";
    return "";
  }

  void _handleSend() async {
    // ANPASSUNG: Senden nur erlauben, wenn Boro nicht schreibt und der Text bereitsteht
    if (isBoroTyping || chatStage > 2 || !showNextUserInput) return;

    // 1. User Nachricht in den Chat einfügen (Index 0, da die Liste reversed ist)
    final userMsg = currentInputText;
    setState(() {
      messages.insert(0, {"sender": "user", "text": userMsg});
      // ANPASSUNG: Textfeld leeren, bis Boros Antwort kommt
      showNextUserInput = false;
    });

    // Wenn es die letzte Nachricht war, beenden wir das Chat-Minispiel
    if (chatStage == 2) {
      // ANPASSUNG: chatStage erhöhen, damit currentInputText leer ist
      setState(() => chatStage++);
      Future.delayed(const Duration(milliseconds: 1000), widget.onCompleted);
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
      // ANPASSUNG: Nächster Text steht jetzt bereit
      showNextUserInput = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ANPASSUNG: Text im Feld bestimmen
    String displayInput = (!showNextUserInput || currentInputText.isEmpty) ? "..." : currentInputText;
    bool canSend = !isBoroTyping && chatStage <= 2 && showNextUserInput;

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
              // ANPASSUNG: Neues Profilbild verwenden
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
              reverse: true, // Wichtig, damit es von unten nach oben wächst
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
                    maxLines: 1, // Verhindert Zeilenumbruch im Fake-Feld
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

        // ANPASSUNG: Fake Tastatur Bild einsetzen und skalieren
        // Die feste Höhe (height: 220) wurde entfernt.
        // Das Bild wird nun direkt eingefügt und mit fitWidth skaliert.
        // Dadurch passt sich die Höhe des Containers automatisch an das Seitenverhältnis des Bildes an,
        // und es wird nichts mehr oben oder unten abgeschnitten.
        Image.asset(
          'assets/keyboard.jpg',
          width: double.infinity,
          fit: BoxFit.fitWidth, // Bild skaliert auf volle Breite, Höhe passt sich an
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
    // Fade-in und Slide-up Animation für jede neue Nachricht
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