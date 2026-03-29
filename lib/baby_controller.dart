import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // NEU
import 'main.dart'; // Für den flutterLocalNotificationsPlugin

class BabyController extends ChangeNotifier {
  double hunger = 100.0;
  double chillLevel = 100.0;
  double babyStress = 0.0;
  double debt = 0.0;
  bool isAlive = true;
  bool isAlarmEnabled = false;

  int donersEaten = 0;
  int deathsCount = 0;
  int jointsSmoked = 0;

  final String secretReviveCode = "4242";
  Timer? _timer;
  SharedPreferences? _prefs;

  final int alarmId = 42;

  DateTime? nextAlarmTime;

  // Notification Konstanten
  final int _statusNotificationId = 888;

  BabyController() {
    _initController();
  }

  Future<void> _initController() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
    _startLifeLoop();

    if (isAlarmEnabled) {
      final alarm = await Alarm.getAlarm(alarmId);
      if (alarm != null) {
        nextAlarmTime = alarm.dateTime; // Zeit aus dem Speicher laden
        notifyListeners();
      } else {
        _scheduleNextAlarm(); // Keiner da? Neuen setzen!
      }
    }
  }

  // --- NEU: Aktualisiert die Ongoing Notification ---
  Future<void> _updateOngoingNotification() async {
    if (!isAlive) {
      await flutterLocalNotificationsPlugin.cancel(_statusNotificationId);
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'baby_status_channel',
      'Baby Status',
      channelDescription: 'Zeigt den dauerhaften Status des Babys an',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,        // Wichtig: Lässt sich nicht wegschieben
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      _statusNotificationId,
      'Baby Status',
      'Magen: ${hunger.toInt()}% | Chill: ${chillLevel.toInt()}% | Stress: ${babyStress.toInt()}%',
      platformChannelSpecifics,
    );
  }

  void _loadData() {
    if (_prefs == null) return;
    hunger = _prefs!.getDouble('hunger') ?? 100.0;
    chillLevel = _prefs!.getDouble('chillLevel') ?? 100.0;
    babyStress = _prefs!.getDouble('babyStress') ?? 0.0;
    debt = _prefs!.getDouble('debt') ?? 0.0;
    isAlive = _prefs!.getBool('isAlive') ?? true;
    isAlarmEnabled = _prefs!.getBool('isAlarmEnabled') ?? false;
    donersEaten = _prefs!.getInt('donersEaten') ?? 0;
    deathsCount = _prefs!.getInt('deathsCount') ?? 0;
    jointsSmoked = _prefs!.getInt('jointsSmoked') ?? 0;

    int? lastSavedMillis = _prefs!.getInt('lastSavedTime');
    if (lastSavedMillis != null && isAlive) {
      final lastSavedDate = DateTime.fromMillisecondsSinceEpoch(lastSavedMillis);
      final elapsedSeconds = DateTime.now().difference(lastSavedDate).inSeconds;

      final ticks = elapsedSeconds ~/ 5;

      if (ticks > 0) {
        for (int i = 0; i < ticks; i++) {
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
            Alarm.stop(alarmId);
            nextAlarmTime = null;
            break;
          }
        }
      }
    }

    // Notification aktualisieren, nachdem Daten geladen sind
    if (isAlive) _updateOngoingNotification();

    notifyListeners();
  }

  Future<void> _saveData() async {
    if (_prefs == null) return;
    await _prefs!.setDouble('hunger', hunger);
    await _prefs!.setDouble('chillLevel', chillLevel);
    await _prefs!.setDouble('babyStress', babyStress);
    await _prefs!.setDouble('debt', debt);
    await _prefs!.setBool('isAlive', isAlive);
    await _prefs!.setBool('isAlarmEnabled', isAlarmEnabled);
    await _prefs!.setInt('donersEaten', donersEaten);
    await _prefs!.setInt('deathsCount', deathsCount);
    await _prefs!.setInt('jointsSmoked', jointsSmoked);
    await _prefs!.setInt('lastSavedTime', DateTime.now().millisecondsSinceEpoch);
  }

  void toggleAlarm(bool value) {
    isAlarmEnabled = value;
    _saveData();
    if (isAlarmEnabled) {
      _scheduleNextAlarm();
    } else {
      Alarm.stop(alarmId);
      nextAlarmTime = null; // Zeit löschen
    }
    notifyListeners();
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
          nextAlarmTime = null;
        }
        _saveData();
        _updateOngoingNotification(); // Update die Notification alle 5 Sek.
        notifyListeners();
      }
    });
  }

  void _scheduleNextAlarm() {
    if (!isAlive || !isAlarmEnabled) return;

    int minSeconds = max(10, 120 - babyStress.toInt());
    int maxSeconds = minSeconds + 30;

    int randomDelay = minSeconds + Random().nextInt(maxSeconds - minSeconds);

    final now = DateTime.now();
    final alarmTime = now.add(Duration(seconds: randomDelay));

    nextAlarmTime = alarmTime;

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: alarmTime,
      assetAudioPath: 'assets/crying.mp3',
      loopAudio: true,
      vibrate: true,
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
    if (isAlarmEnabled) {
      _scheduleNextAlarm();
    }
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
    _updateOngoingNotification();
    notifyListeners();
  }

  void smoke(double amount) {
    if (!isAlive) return;
    chillLevel = (chillLevel + amount).clamp(0, 100);
    jointsSmoked++;
    _saveData();
    _updateOngoingNotification();
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
      _updateOngoingNotification();
      notifyListeners();
      return true;
    }
    return false;
  }
}