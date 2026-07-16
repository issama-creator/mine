import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_config.dart';

class ScoreManager {
  static const _highScoreKey = 'mine_slice_high_score';
  static const _bestMetersKey = 'mine_slice_best_meters';
  static const _bestComboKey = 'mine_slice_best_combo';

  int score = 0;
  int combo = 0;
  int bestCombo = 0;
  int highScore = 0;
  int bestMeters = 0;
  int bestComboEver = 0;
  double frenzyTimer = 0;

  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<int> comboNotifier = ValueNotifier(0);
  final ValueNotifier<bool> frenzyNotifier = ValueNotifier(false);
  final ValueNotifier<String> popupNotifier = ValueNotifier('');
  final ValueNotifier<int> highScoreNotifier = ValueNotifier(0);
  final ValueNotifier<int> bestMetersNotifier = ValueNotifier(0);
  final ValueNotifier<int> bestComboEverNotifier = ValueNotifier(0);

  double get multiplier {
    var m = 1.0;
    if (combo >= GameConfig.combo5) m = 1.5;
    if (combo >= GameConfig.frenzy10 || frenzyTimer > 0) m = 2.0;
    return m;
  }

  Future<void> loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      highScore = prefs.getInt(_highScoreKey) ?? 0;
      bestMeters = prefs.getInt(_bestMetersKey) ?? 0;
      bestComboEver = prefs.getInt(_bestComboKey) ?? 0;
      highScoreNotifier.value = highScore;
      bestMetersNotifier.value = bestMeters;
      bestComboEverNotifier.value = bestComboEver;
    } catch (_) {}
  }

  Future<void> _persistRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, highScore);
      await prefs.setInt(_bestMetersKey, bestMeters);
      await prefs.setInt(_bestComboKey, bestComboEver);
    } catch (_) {}
  }

  void resetRun() {
    score = 0;
    combo = 0;
    frenzyTimer = 0;
    scoreNotifier.value = 0;
    comboNotifier.value = 0;
    frenzyNotifier.value = false;
    popupNotifier.value = '';
  }

  void tick(double dt) {
    if (frenzyTimer > 0) {
      frenzyTimer -= dt;
      if (frenzyTimer <= 0) frenzyNotifier.value = false;
    }
  }

  int addSlice(int basePoints, {required int sliceCount, bool perfect = false}) {
    combo += sliceCount;
    if (combo > bestCombo) bestCombo = combo;
    comboNotifier.value = combo;

    var pts = (basePoints * multiplier).round();
    if (perfect) pts *= 2;
    score += pts;
    scoreNotifier.value = score;

    String popup = '';
    if (perfect) popup = 'PERFECT';
    if (combo >= GameConfig.combo3) popup = 'COMBO x$combo';
    if (combo >= GameConfig.frenzy10 && frenzyTimer <= 0) {
      frenzyTimer = GameConfig.frenzyDuration;
      frenzyNotifier.value = true;
      popup = 'FRENZY!';
    } else if (frenzyTimer > 0) {
      frenzyNotifier.value = true;
    }
    if (popup.isNotEmpty) popupNotifier.value = popup;

    return pts;
  }

  void breakCombo() {
    combo = 0;
    comboNotifier.value = 0;
  }

  void tryUpdateHighScore() {
    if (score > highScore) {
      highScore = score;
      highScoreNotifier.value = highScore;
    }
  }

  void tryUpdateRecords({required int meters}) {
    var changed = false;
    if (score > highScore) {
      highScore = score;
      highScoreNotifier.value = highScore;
      changed = true;
    }
    if (meters > bestMeters) {
      bestMeters = meters;
      bestMetersNotifier.value = bestMeters;
      changed = true;
    }
    if (bestCombo > bestComboEver) {
      bestComboEver = bestCombo;
      bestComboEverNotifier.value = bestComboEver;
      changed = true;
    }
    if (changed) _persistRecords();
  }
}
