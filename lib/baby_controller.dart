import 'dart:async';
import 'package:flutter/material.dart';

class BabyController extends ChangeNotifier {
  // Die Statuswerte des Babys
  double hunger = 100.0;
  double chillLevel = 100.0;
  bool isAlive = true;
  
  // DEIN GEHEIMER CODE - ändere ihn, wenn du willst!
  final String secretReviveCode = "4242"; 
  
  Timer? _timer;

  BabyController() {
    _startLifeLoop();
  }

  // Dieser Loop lässt die Werte alle 5 Sekunden sinken
  void _startLifeLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isAlive) {
        // Schwierigkeitsgrad: Höhere Werte = schnellerer Tod
        hunger -= 1.5; 
        chillLevel -= 1.0;

        if (hunger <= 0 || chillLevel <= 0) {
          hunger = 0;
          chillLevel = 0;
          isAlive = false;
          _timer?.cancel();
        }
        notifyListeners(); // Sagt der App: "Update die Anzeige!"
      }
    });
  }

  // Funktion zum Döner füttern
  void feed(double amount) {
    if (!isAlive) return;
    hunger = (hunger + amount).clamp(0, 100);
    notifyListeners();
  }

  // Funktion zum Joint rauchen
  void smoke(double amount) {
    if (!isAlive) return;
    chillLevel = (chillLevel + amount).clamp(0, 100);
    notifyListeners();
  }

  // Der "Gott-Modus" für den Best Man
  bool revive(String code) {
    if (code == secretReviveCode) {
      isAlive = true;
      hunger = 60.0;
      chillLevel = 60.0;
      _startLifeLoop();
      notifyListeners();
      return true;
    }
    return false;
  }
}