import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local player preferences — sound, vibration.
class SettingsManager {
  SettingsManager._();
  static final SettingsManager instance = SettingsManager._();

  static const _soundKey = 'mine_slice_sound';
  static const _vibrationKey = 'mine_slice_vibration';

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  final ValueNotifier<bool> soundNotifier = ValueNotifier(true);
  final ValueNotifier<bool> vibrationNotifier = ValueNotifier(true);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      soundEnabled = prefs.getBool(_soundKey) ?? true;
      vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
      soundNotifier.value = soundEnabled;
      vibrationNotifier.value = vibrationEnabled;
    } catch (_) {}
  }

  Future<void> setSound(bool value) async {
    soundEnabled = value;
    soundNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundKey, value);
    } catch (_) {}
  }

  Future<void> setVibration(bool value) async {
    vibrationEnabled = value;
    vibrationNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationKey, value);
    } catch (_) {}
  }
}
