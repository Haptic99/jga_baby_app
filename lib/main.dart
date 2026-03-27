import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'baby_controller.dart';
import 'smoke_minigame_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BabyController(),
      child: MaterialApp(
        title: 'JGA Baby Watch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
          fontFamily: 'Nunito', // Nutzt Standard-Font, bis du Custom Fonts einbindest
        ),
        home: const BabyHomeScreen(),
      ),
    ),
  );
}

// Hilfsliste für den "Text-Outline" Effekt (schwarze Ränder um weißen Text)
const List<Shadow> outlineShadows = [
  Shadow(offset: Offset(-2, -2), color: Colors.black),
  Shadow(offset: Offset(2, -2), color: Colors.black),
  Shadow(offset: Offset(-2, 2), color: Colors.black),
  Shadow(offset: Offset(2, 2), color: Colors.black),
  Shadow(offset: Offset(0, 3), color: Colors.black),
];

class BabyHomeScreen extends StatelessWidget {
  const BabyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final baby = Provider.of<BabyController>(context);

    // Zeige den Todesbildschirm, wenn das Baby tot ist
    if (!baby.isAlive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: _buildDeathUI(context, baby)),
      );
    }

    // Hauptmenü-UI
    return Scaffold(
      body: Stack(
        children: [
          // 1. Hintergrund-Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF5E00), Color(0xFFB026FF)],
              ),
            ),
          ),
          // 2. Punktemuster Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: CustomPaint(painter: DottedPatternPainter()),
            ),
          ),
          // 3. Hauptinhalt
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildStatusBars(baby),
                            const SizedBox(height: 24),

                            // Nimmt den übrigen Platz ein
                            Expanded(child: Center(child: _buildFamilyPhoto())),

                            const SizedBox(height: 24),
                            _buildActionButtons(context, baby),
                            const SizedBox(height: 24),
                            _buildStatsPanel(baby),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Transform.rotate(
      angle: -0.017, // ca. -1 Grad rotiert
      child: const Text(
        "Mini Boro Tamagochi",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
          shadows: outlineShadows,
        ),
      ),
    );
  }

  Widget _buildStatusBars(BabyController baby) {
    return Row(
      children: [
        Expanded(
          child: _buildSingleProgressBar(
            title: "Mageninhalt",
            iconWidget: const Text("🌯", style: TextStyle(fontSize: 48)),
            percentage: baby.hunger,
            color: Colors.orange,
            label: "${baby.hunger.toInt()}% Full",
            iconOffset: -10,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSingleProgressBar(
            title: "Chill-Faktor",
            // Das Bild wird hier als iconWidget übergeben und deutlich kleiner dargestellt (height 30)
            iconWidget: Image.asset('assets/weed_leaf.png', height: 80),
            percentage: baby.chillLevel,
            color: Colors.green,
            label: "${baby.chillLevel.toInt()}% Zen",
            iconOffset: -20,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleProgressBar({
    required String title,
    required Widget iconWidget,
    required double percentage,
    required Color color,
    required String label,
    required double iconOffset,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: outlineShadows,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 24,
              margin: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        border: const Border(right: BorderSide(color: Colors.black, width: 3)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: iconOffset,
              child: iconWidget,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              shadows: outlineShadows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyPhoto() {
    return Transform.rotate(
      angle: 0.017, // ~1 Grad rotiert
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 6))],
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.purple[900], // Das ist die Hintergrundfarbe, die um das kleinere Bild herum sichtbar wird
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: AspectRatio(
              aspectRatio: 4 / 3, // Das Verhältnis des Rahmens bleibt groß und gleich
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // --- NEU: Bild verkleinert und zentriert IM Rahmen ---
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.95, // Macht das Bild auf 70% (also 30% kleiner) der inneren Breite
                      heightFactor: 0.95, // Macht das Bild auch in der Höhe 30% kleiner
                      child: Image.asset('assets/family_boro.png', fit: BoxFit.cover),
                    ),
                  ),
                  // ---------------------------------------------------
                  // Halbtransparentes Overlay über den gesamten inneren Bereich
                  Container(color: Colors.black.withValues(alpha: 0.2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BabyController baby) {
    return Row(
      children: [
        Expanded(
          child: _buildBrutalistButton(
            text: "Döner essen",
            iconWidget: const Text("🌯", style: TextStyle(fontSize: 40)),
            color: Colors.orange,
            onTap: () => baby.feed(20),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBrutalistButton(
            text: "Joint rauchen",
            // Das Bild hier ebenfalls anstelle des Emojis, kleiner und zentriert
            iconWidget: Image.asset('assets/weed_leaf.png', height: 1000),
            color: Colors.green,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SmokeMinigameScreen()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrutalistButton({
    required String text,
    required Widget iconWidget,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 6))],
        ),
        child: Column(
          children: [
            // SizedBox sorgt dafür, dass die Emojis und Bilder unabhängig von ihrer eigenen Größe
            // denselben Platz einnehmen und die darunter liegenden Texte auf der exakt gleichen Höhe bleiben
            SizedBox(
              height: 48,
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(offset: Offset(-1, -1), color: Colors.black),
                  Shadow(offset: Offset(1, -1), color: Colors.black),
                  Shadow(offset: Offset(-1, 1), color: Colors.black),
                  Shadow(offset: Offset(1, 1), color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel(BabyController baby) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // Hier .withValues angewendet
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(const Text("💰", style: TextStyle(fontSize: 32)), "Schulden\nin CHF", baby.debt.toStringAsFixed(2)),
          _buildStatItem(const Text("🌯", style: TextStyle(fontSize: 32)), "Gegessene\nDöner", "${baby.donersEaten}"),
          _buildStatItem(Image.asset('assets/weed_leaf.png', height: 28), "Gerauchte\nJoints", "${baby.jointsSmoked}"),
          _buildStatItem(const Text("☠️", style: TextStyle(fontSize: 32)), "Todesfälle", "${baby.deathsCount}"),
        ],
      ),
    );
  }

  Widget _buildStatItem(Widget iconWidget, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          // SizedBox für einheitliche Höhe der Icons/Bilder in der Leiste
          SizedBox(height: 40, child: Center(child: iconWidget)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.1, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Die bestehende "Todes-UI" - leicht angepasst an das neue Layout
  Widget _buildDeathUI(BuildContext context, BabyController baby) {
    final TextEditingController codeController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("💀", style: TextStyle(fontSize: 100)),
          const Text("BABY TOT!", style: TextStyle(color: Colors.red, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text("TRINK EINEN SHOT!\nDann Code eingeben:", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 30),
          TextField(
            controller: codeController,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
              labelText: "Geheimcode",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => baby.revive(codeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("WIEDERBELEBEN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter für das halbtransparente Punktemuster im Hintergrund
class DottedPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Hier .withValues angewendet
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    const double spacing = 40.0; // Abstand der Punkte analog zum CSS "background-size"

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + spacing / 2, y + spacing / 2), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}