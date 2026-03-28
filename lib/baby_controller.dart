import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';

class BabyController extends ChangeNotifier {
  double hunger = 100.0;
  double chillLevel = 100.0;
  double babyStress = 0.0;
  double debt = 0.0;
  bool isAlive = true;

  int donersEaten = 0;
  int deathsCount = 0;
  int jointsSmoked = 0;

  final String secretReviveCode = "4242";
  Timer? _timer;
  SharedPreferences? _prefs;

  final int alarmId = 42;

  BabyController() {
    _initController();
  }

  Future<void> _initController() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
    _startLifeLoop();

    if (!await Alarm.hasAlarm()) {
      _scheduleNextAlarm();
    }
  }

  void _loadData() {
    if (_prefs == null) return;
    hunger = _prefs!.getDouble('hunger') ?? 100.0;
    chillLevel = _prefs!.getDouble('chillLevel') ?? 100.0;
    babyStress = _prefs!.getDouble('babyStress') ?? 0.0;
    debt = _prefs!.getDouble('debt') ?? 0.0;
    isAlive = _prefs!.getBool('isAlive') ?? true;
    donersEaten = _prefs!.getInt('donersEaten') ?? 0;
    deathsCount = _prefs!.getInt('deathsCount') ?? 0;
    jointsSmoked = _prefs!.getInt('jointsSmoked') ?? 0;
    notifyListeners();
  }

  Future<void> _saveData() async {
    if (_prefs == null) return;
    await _prefs!.setDouble('hunger', hunger);
    await _prefs!.setDouble('chillLevel', chillLevel);
    await _prefs!.setDouble('babyStress', babyStress);
    await _prefs!.setDouble('debt', debt);
    await _prefs!.setBool('isAlive', isAlive);
    await _prefs!.setInt('donersEaten', donersEaten);
    await _prefs!.setInt('deathsCount', deathsCount);
    await _prefs!.setInt('jointsSmoked', jointsSmoked);
  }

  void _startLifeLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isAlive) {
        hunger -= 1.5;
        chillLevel -= 1.0;
        if (hunger < 50 || chillLevel < 50) {
          babyStress = (babyStress + 0.5).clamp(0, 100);
        }

        if (hunger <= 0 || chillLevel <= 0) {
          hunger = 0;
          chillLevel = 0;
          isAlive = false;
          deathsCount++;
          _timer?.cancel();
          Alarm.stop(alarmId);
        }
        _saveData();
        notifyListeners();
      }
    });
  }

  // --- KORRIGIERTE ALARM LOGIK ---
  void _scheduleNextAlarm() {
    if (!isAlive) return;

    int minSeconds = max(10, 120 - babyStress.toInt());
    int maxSeconds = minSeconds + 30;

    int randomDelay = minSeconds + Random().nextInt(maxSeconds - minSeconds);

    final now = DateTime.now();
    final alarmTime = now.add(Duration(seconds: randomDelay));

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: alarmTime,
      assetAudioPath: 'assets/crying.mp3',
      loopAudio: true,
      vibrate: true,
      // In Version 4.1.1 werden volume und fadeDuration noch direkt übergeben
      volume: 1.0,
      fadeDuration: 3.0,
      notificationSettings: const NotificationSettings(
        title: 'Baby Boro schreit!',
        body: 'Mach die App auf und beruhige es!',
      ),
      warningNotificationOnKill: true,
    );

    Alarm.set(alarmSettings: alarmSettings);
  }

  void stopAlarm() {
    Alarm.stop(alarmId);
    babyStress = (babyStress - 10).clamp(0, 100);
    _saveData();
    _scheduleNextAlarm();
    notifyListeners();
  }

  void evaluateGinFilling(double accuracyLevel) {
    if (accuracyLevel > 0.8) {
      babyStress = (babyStress - 20).clamp(0, 100);
    } else {
      babyStress = (babyStress + (1.0 - accuracyLevel) * 50).clamp(0, 100);
    }
    _saveData();
    _scheduleNextAlarm();
    notifyListeners();
  }

  void addDebt(double amount) {
    debt += amount;
    _saveData();
    notifyListeners();
  }

  void feed(double amount) {
    if (!isAlive) return;
    hunger = (hunger + amount).clamp(0, 100);
    donersEaten++;
    _saveData();
    notifyListeners();
  }

  void smoke(double amount) {
    if (!isAlive) return;
    chillLevel = (chillLevel + amount).clamp(0, 100);
    jointsSmoked++;
    _saveData();
    notifyListeners();
  }

  bool revive(String code) {
    if (code == secretReviveCode) {
      isAlive = true;
      hunger = 60.0;
      chillLevel = 60.0;
      babyStress = 0.0;
      _startLifeLoop();
      _scheduleNextAlarm();
      _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }
}