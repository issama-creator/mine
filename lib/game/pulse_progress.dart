import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/hazard.dart';
import 'pulse_haunt.dart';

/// Meta progression, daily challenge, records — persisted locally.
class PulseProgress {
  PulseProgress._();
  static final PulseProgress instance = PulseProgress._();

  static const _kCoins = 'pulse_coins';
  static const _kSkin = 'pulse_skin';
  static const _kUnlocked = 'pulse_unlocked';
  static const _kBestClose = 'pulse_best_close';
  static const _kBestMeters = 'pulse_best_meters';
  static const _kBestForm = 'pulse_best_form';
  static const _kDailyDay = 'pulse_daily_day';
  static const _kDailyDone = 'pulse_daily_done';
  static const _kStationsTotal = 'pulse_stations';
  static const _kPendingHaunt = 'pulse_pending_haunt';
  static const _kCapturedHaunts = 'pulse_captured_haunts';

  final ValueNotifier<int> coins = ValueNotifier(0);
  final ValueNotifier<String> selectedSkinId = ValueNotifier('neon');
  final ValueNotifier<int> bestClose = ValueNotifier(0);
  final ValueNotifier<int> bestMeters = ValueNotifier(0);
  final ValueNotifier<int> bestForm = ValueNotifier(0);
  final ValueNotifier<bool> dailyDone = ValueNotifier(false);
  final ValueNotifier<int> stationsReached = ValueNotifier(0);
  final ValueNotifier<HauntRecord?> pendingHaunt = ValueNotifier(null);
  final ValueNotifier<int> capturedHauntCount = ValueNotifier(0);

  final Set<String> _unlocked = {'neon'};
  final List<HauntRecord> _captured = [];
  bool _loaded = false;

  int get dailySeed {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  /// Rotating daily goal — same for everyone on the same calendar day.
  DailyGoal get dailyGoal {
    final day = DateTime.now().day;
    return switch (day % 3) {
      0 => const DailyGoal(
          type: DailyGoalType.reachMeters,
          target: 40,
          label: 'Пройди 40 m за день',
        ),
      1 => const DailyGoal(
          type: DailyGoalType.smashStreak,
          target: 5,
          label: '5 SMASH подряд в одном забеге',
        ),
      _ => const DailyGoal(
          type: DailyGoalType.formStreak,
          target: 8,
          label: 'FORM streak 8+ в забеге',
        ),
    };
  }

  Future<void> load() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    coins.value = p.getInt(_kCoins) ?? 0;
    selectedSkinId.value = p.getString(_kSkin) ?? 'neon';
    bestClose.value = p.getInt(_kBestClose) ?? 0;
    bestMeters.value = p.getInt(_kBestMeters) ?? 0;
    bestForm.value = p.getInt(_kBestForm) ?? 0;
    stationsReached.value = p.getInt(_kStationsTotal) ?? 0;
    final pendingRaw = p.getString(_kPendingHaunt);
    pendingHaunt.value = pendingRaw == null
        ? null
        : HauntRecord.fromJson(
            jsonDecode(pendingRaw) as Map<String, dynamic>,
          );
    _captured
      ..clear()
      ..addAll(HauntRecord.decodeList(p.getString(_kCapturedHaunts)));
    capturedHauntCount.value = _captured.length;
    _unlocked
      ..clear()
      ..addAll(p.getStringList(_kUnlocked) ?? ['neon']);
    final savedDay = p.getInt(_kDailyDay) ?? 0;
    dailyDone.value =
        savedDay == dailySeed && (p.getBool(_kDailyDone) ?? false);
    _loaded = true;
  }

  bool isUnlocked(String skinId) => _unlocked.contains(skinId);

  Future<bool> buySkin(String skinId, int cost) async {
    if (_unlocked.contains(skinId) || coins.value < cost) return false;
    coins.value -= cost;
    _unlocked.add(skinId);
    selectedSkinId.value = skinId;
    await _save();
    return true;
  }

  Future<void> selectSkin(String skinId) async {
    if (!_unlocked.contains(skinId)) return;
    selectedSkinId.value = skinId;
    await _save();
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    coins.value += amount;
    await _save();
  }

  Future<void> recordRun({
    required int meters,
    required int formStreak,
    required int closeCount,
    required bool dailyMet,
  }) async {
    var changed = false;
    if (meters > bestMeters.value) {
      bestMeters.value = meters;
      changed = true;
    }
    if (formStreak > bestForm.value) {
      bestForm.value = formStreak;
      changed = true;
    }
    if (closeCount > bestClose.value) {
      bestClose.value = closeCount;
      changed = true;
    }
    if (dailyMet && !dailyDone.value) {
      dailyDone.value = true;
      changed = true;
    }
    if (changed) await _save();
  }

  Future<void> addStation() async {
    stationsReached.value += 1;
    await _save();
  }

  int metersFromRecord(int current) =>
      (bestMeters.value - current).clamp(0, 9999);

  List<HauntRecord> get capturedHaunts => List.unmodifiable(_captured);

  /// Save killer hazard as next run's haunt (or strengthen if haunt killed you).
  Future<void> registerDeath({
    required HazardKind kind,
    required int lane,
    required int meters,
    required bool killedByHaunt,
  }) async {
    if (killedByHaunt && pendingHaunt.value != null) {
      final p = pendingHaunt.value!;
      pendingHaunt.value = p.withPower(p.power + 1);
    } else if (kind == HazardKind.shard ||
        kind == HazardKind.boost) {
      // Collectibles don't haunt.
    } else {
      pendingHaunt.value = HauntRecord.fromDeath(
        kind: kind,
        lane: lane,
        meters: meters,
      );
    }
    await _save();
  }

  /// Perfect revenge — haunt joins collection, clears pending.
  Future<int> captureHaunt({required int atMeters}) async {
    final p = pendingHaunt.value;
    if (p == null) return 0;
    final captured = p.captured(atMeters);
    _captured.insert(0, captured);
    if (_captured.length > 40) _captured.removeLast();
    capturedHauntCount.value = _captured.length;
    pendingHaunt.value = null;
    final reward = 15 + p.power * 8;
    coins.value += reward;
    await _save();
    return reward;
  }

  String shareLine({
    required int meters,
    required int form,
    required int close,
    int haunts = 0,
  }) =>
      haunts > 0
          ? '$meters m · FORM $form · $close CLOSE · $haunts 👻'
          : '$meters m · FORM $form · $close CLOSE';

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kCoins, coins.value);
    await p.setString(_kSkin, selectedSkinId.value);
    await p.setStringList(_kUnlocked, _unlocked.toList());
    await p.setInt(_kBestClose, bestClose.value);
    await p.setInt(_kBestMeters, bestMeters.value);
    await p.setInt(_kBestForm, bestForm.value);
    await p.setInt(_kStationsTotal, stationsReached.value);
    await p.setInt(_kDailyDay, dailySeed);
    await p.setBool(_kDailyDone, dailyDone.value);
    if (pendingHaunt.value == null) {
      await p.remove(_kPendingHaunt);
    } else {
      await p.setString(
        _kPendingHaunt,
        jsonEncode(pendingHaunt.value!.toJson()),
      );
    }
    await p.setString(_kCapturedHaunts, HauntRecord.encodeList(_captured));
  }
}

enum DailyGoalType { reachMeters, smashStreak, formStreak }

class DailyGoal {
  const DailyGoal({
    required this.type,
    required this.target,
    required this.label,
  });

  final DailyGoalType type;
  final int target;
  final String label;
}
