import 'dart:async';
import 'package:flutter/material.dart';

class BabyController extends ChangeNotifier {
  double hunger = 100.0;
  double chillLevel = 100.0;
  double debt = 0.0; // Schulden in CHF
  bool isAlive = true;

  // NEU: Statistiken
  int donersEaten = 0;
  int deathsCount = 0;
  int jointsSmoked = 0;

  final String secretReviveCode = "4242";
  Timer? _timer;

  BabyController() {
    _startLifeLoop();
  }

  void _startLifeLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isAlive) {
        hunger -= 1.5;
        chillLevel -= 1.0;

        if (hunger <= 0 || chillLevel <= 0) {
          hunger = 0;
          chillLevel = 0;
          isAlive = false;
          deathsCount++; // Statistik: Tot erhöht
          _timer?.cancel();
        }
        notifyListeners();
      }
    });
  }

  void addDebt(double amount) {
    debt += amount;
    notifyListeners();
  }

  void feed(double amount) {
    if (!isAlive) return;
    hunger = (hunger + amount).clamp(0, 100);
    donersEaten++; // Statistik: Döner erhöht
    notifyListeners();
  }

  void smoke(double amount) {
    if (!isAlive) return;
    chillLevel = (chillLevel + amount).clamp(0, 100);
    jointsSmoked++; // Statistik: Joints erhöht
    notifyListeners();
  }

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