import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jga_baby_app/main.dart';
import 'package:jga_baby_app/baby_controller.dart'; // Wichtig für den Provider

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Baue die App auf und triggere einen Frame
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => BabyController(),
        child: const MaterialApp(
          home: BabyHomeScreen(),
        ),
      ),
    );

    // Prüfe, ob die App erfolgreich gestartet ist (wir suchen nach dem Text "Mini Boro")
    expect(find.text('Mini Boro'), findsOneWidget);
  });
}