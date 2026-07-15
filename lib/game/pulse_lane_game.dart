import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/pulse_colors.dart';
import 'components/fx.dart';
import 'components/hazard.dart';
import 'components/player_pulse.dart';
import 'components/tunnel_backdrop.dart';
import 'pulse_haunt.dart';
import 'pulse_progress.dart';
import 'pulse_sfx.dart';
import 'pulse_skins.dart';
import 'systems/pulse_config.dart';
import 'systems/tunnel_space.dart';

class _GhostPoint {
  _GhostPoint(this.lane, this.y);
  final double lane;
  final double y;
}

/// Pulse — rhythm form runner. Slim / Smash / Swipe.
class PulseLaneGame extends FlameGame with KeyboardEvents {
  PulseLaneGame() {
    space = TunnelSpace(Size.zero);
    backdrop = TunnelBackdrop(space: space);
    player = PlayerPulse(space: space);
  }

  late final TunnelSpace space;
  late final TunnelBackdrop backdrop;
  late final PlayerPulse player;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> meters = ValueNotifier(0);
  final ValueNotifier<int> bestMeters = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<int> best = ValueNotifier(0);
  final ValueNotifier<bool> started = ValueNotifier(false);
  final ValueNotifier<int> speedTier = ValueNotifier(0);
  final ValueNotifier<String> failReason = ValueNotifier('');
  final ValueNotifier<String> tip = ValueNotifier('');
  final ValueNotifier<String> formLabel = ValueNotifier('SMASH');
  final ValueNotifier<int> formStreak = ValueNotifier(0);
  final ValueNotifier<int> bestFormStreak = ValueNotifier(0);
  final ValueNotifier<bool> feverActive = ValueNotifier(false);
  final ValueNotifier<double> warnFlash = ValueNotifier(0);
  final ValueNotifier<int> runCoins = ValueNotifier(0);
  final ValueNotifier<int> toStation = ValueNotifier(PulseConfig.stationDistance);
  final ValueNotifier<int> closeCount = ValueNotifier(0);
  final ValueNotifier<int> feverHits = ValueNotifier(0);
  final ValueNotifier<double> coinMultiplier = ValueNotifier(1.0);
  final ValueNotifier<double> holdRemain = ValueNotifier(0);
  final ValueNotifier<int> stationsThisRun = ValueNotifier(0);
  final ValueNotifier<bool> secondChanceOffer = ValueNotifier(false);
  final ValueNotifier<String> dailyLabel = ValueNotifier('');
  final ValueNotifier<String> hauntLabel = ValueNotifier('');
  final ValueNotifier<String> stationToast = ValueNotifier('');

  final _shake = ScreenShake();
  final _progress = PulseProgress.instance;

  late math.Random _rng;
  late math.Random _dailyRng;

  double _runTime = 0;
  double _travel = 0;
  double _beatAcc = 0;
  double _spawnTimer = 0;
  double _nextSpawn = PulseConfig.spawnWarmup;
  double _holdTimer = 0;
  double _deathFlash = 0;
  double _warnDecay = 0;
  double _feverTimer = 0;
  double _slowMoTimer = 0;
  double _boostTimer = 0;
  double _stationToastTimer = 0;
  bool _fingerDown = false;
  bool _suppressHold = false;
  bool isGameOver = false;
  bool _loaded = false;
  bool _tutorial = true;
  bool _feverTimeUsed = false;
  bool _secondChanceUsed = false;
  bool _riskyNextPattern = false;
  int _tutStep = 0;
  int _patternBeat = 0;
  int _formStreakVal = 0;
  int _runFormBest = 0;
  int _bestFormVal = 0;
  int _smashStreakRun = 0;
  int _runSmashBest = 0;
  int _nextStationAt = PulseConfig.stationDistance;
  int lastStationBonus = 25;
  Offset _shakeOff = Offset.zero;
  int _lastTier = 0;
  Hazard? _deathHazard;
  bool _hauntSpawned = false;
  static const int _hauntSpawnMeter = 25;

  static bool _everFinishedTutorial = false;
  static final List<_GhostPoint> _bestGhost = [];

  final List<_GhostPoint> _ghostRecording = [];
  double _ghostSampleAcc = 0;

  double get beatPhase =>
      (_beatAcc / PulseConfig.beatInterval).clamp(0.0, 1.0);

  double get worldSpeed {
    final m = _travel;
    final distT = (m / PulseConfig.metersToMaxSpeed).clamp(0.0, 1.0);
    final distEase = distT * distT * (3 - 2 * distT);
    final gentleStart = m < 20 ? 0.65 + (m / 20) * 0.35 : 1.0;
    var base = PulseConfig.baseSpeed +
        (PulseConfig.maxSpeed - PulseConfig.baseSpeed) * distEase;
    base *= gentleStart;
    if (_tutorial) base *= 0.78;
    if (_feverTimer > 0) base *= 1.12;
    if (_boostTimer > 0) base *= 1.22;
    if (_slowMoTimer > 0) base *= 0.42;
    return base;
  }

  @override
  Color backgroundColor() => PulseColors.voidDeep;

  @override
  Future<void> onLoad() async {
    await _progress.load();
    space.size = Size(size.x > 0 ? size.x : 800, size.y > 0 ? size.y : 600);
    bestMeters.value = _progress.bestMeters.value;
    bestFormStreak.value = _progress.bestForm.value;
    _bestFormVal = _progress.bestForm.value;
    _applySkin(_progress.selectedSkinId.value);
    _progress.selectedSkinId.addListener(_onSkinChanged);
    dailyLabel.value = _progress.dailyGoal.label;
    _initRng();
    await add(backdrop);
    await add(player);
    _loaded = true;
    overlays.add(PulseConfig.title);
  }

  void _onSkinChanged() => _applySkin(_progress.selectedSkinId.value);

  void _applySkin(String id) {
    player.skin = PulseSkins.byId(id);
  }

  void _initRng() {
    final seed = _progress.dailySeed;
    _dailyRng = math.Random(seed);
    _rng = math.Random(seed ^ 0xBEEF);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      space.size = Size(size.x, size.y);
    }
  }

  void startRun() {
    if (!_loaded) return;
    _clearHazards();
    player.reset();
    _applySkin(_progress.selectedSkinId.value);
    score.value = 0;
    meters.value = 0;
    combo.value = 0;
    runCoins.value = 0;
    closeCount.value = 0;
    feverHits.value = 0;
    speedTier.value = 0;
    formStreak.value = 0;
    stationsThisRun.value = 0;
    toStation.value = PulseConfig.stationDistance;
    coinMultiplier.value = 1.0;
    holdRemain.value = 0;
    secondChanceOffer.value = false;
    stationToast.value = '';
    _formStreakVal = 0;
    _runFormBest = 0;
    _smashStreakRun = 0;
    _runSmashBest = 0;
    _nextStationAt = PulseConfig.stationDistance;
    failReason.value = '';
    tip.value = _everFinishedTutorial ? '' : 'СВАЙП ← → от красного ✕';
    formLabel.value = 'SMASH';
    feverActive.value = false;
    warnFlash.value = 0;
    _runTime = 0;
    _travel = 0;
    _beatAcc = 0;
    _spawnTimer = 0;
    _nextSpawn = 1.6;
    _lastTier = 0;
    _patternBeat = 0;
    _holdTimer = 0;
    _deathFlash = 0;
    _warnDecay = 0;
    _feverTimer = 0;
    _boostTimer = 0;
    _stationToastTimer = 0;
    _slowMoTimer = 0;
    _feverTimeUsed = false;
    _secondChanceUsed = false;
    _riskyNextPattern = false;
    _fingerDown = false;
    _suppressHold = false;
    _tutorial = !_everFinishedTutorial;
    _tutStep = 0;
    _ghostRecording.clear();
    _ghostSampleAcc = 0;
    _deathHazard = null;
    _hauntSpawned = false;
    _setHauntTip();
    player.wantCollapse = false;
    isGameOver = false;
    started.value = true;
    overlays.remove(PulseConfig.title);
    overlays.remove(PulseConfig.gameOver);
    overlays.remove(PulseConfig.continueRun);
    overlays.add(PulseConfig.input, priority: 0);
    overlays.add(PulseConfig.hud, priority: 1);
    resumeEngine();
  }

  void restart() => startRun();

  void setCollapse(bool v) {
    if (!_loaded || !started.value || isGameOver) return;
    final was = player.wantCollapse;
    player.wantCollapse = v;
    if (v && !was) PulseSfx.slimTick();
    if (!v && was) PulseSfx.smashHit();
  }

  void nudgeLane(int delta) {
    if (!_loaded || !started.value || isGameOver) return;
    _suppressHold = true;
    player.moveLane(delta);
    HapticFeedback.selectionClick();
  }

  void touchDown() {
    if (!_loaded || !started.value || isGameOver) return;
    _fingerDown = true;
    _suppressHold = false;
    _holdTimer = 0;
  }

  void touchUp() {
    _fingerDown = false;
    _holdTimer = 0;
    _suppressHold = false;
    setCollapse(false);
  }

  void useSecondChance() {
    if (!secondChanceOffer.value) return;
    secondChanceOffer.value = false;
    overlays.remove(PulseConfig.continueRun);
    isGameOver = false;
    _deathFlash = 0;
    player.wrongOutline = 0;
    _slowMoTimer = 0.8;
    for (final h in children.whereType<Hazard>().toList()) {
      if ((h.depth - PulseConfig.playerDepth).abs() < 0.12) {
        h.removeFromParent();
      }
    }
    resumeEngine();
    add(
      FloatingText(
        at: Vector2(size.x * 0.5, size.y * 0.3),
        text: 'CONTINUED',
        color: PulseColors.pulse,
      ),
    );
  }

  void declineSecondChance() {
    if (!secondChanceOffer.value) return;
    secondChanceOffer.value = false;
    overlays.remove(PulseConfig.continueRun);
    _finalizeGameOver();
  }

  @override
  void update(double dt) {
    if (!_loaded || !started.value) {
      super.update(dt);
      _shakeOff = _shake.update(dt);
      if (_deathFlash > 0) _deathFlash -= dt;
      return;
    }

    if (isGameOver && !secondChanceOffer.value) {
      super.update(dt);
      _shakeOff = _shake.update(dt);
      if (_deathFlash > 0) _deathFlash -= dt;
      return;
    }

    super.update(dt);
    _shakeOff = _shake.update(dt);
    if (_slowMoTimer > 0) _slowMoTimer -= dt;
    if (_boostTimer > 0) _boostTimer -= dt;
    if (_stationToastTimer > 0) {
      _stationToastTimer -= dt;
      if (_stationToastTimer <= 0) stationToast.value = '';
    }
    if (_warnDecay > 0) {
      _warnDecay -= dt;
      warnFlash.value = (_warnDecay / 0.35).clamp(0.0, 1.0);
      backdrop.warnFlash = warnFlash.value;
      player.wrongOutline = warnFlash.value;
    } else {
      warnFlash.value = 0;
      backdrop.warnFlash = 0;
      if (player.wrongOutline > 0 && player.correctGlow <= 0) {
        player.wrongOutline = 0;
      }
    }

    _runTime += dt;
    _travel += worldSpeed * dt * PulseConfig.metersPerDepth;
    final m = _travel.floor();
    if (m != meters.value) {
      meters.value = m;
      toStation.value = (_nextStationAt - m).clamp(0, 999);
      _checkStation(m);
      _trySpawnHaunt(m);
      _recordGhost();
    }

    _beatAcc += dt;
    backdrop.beatPhase = beatPhase;
    if (_feverTimer > 0) {
      _feverTimer -= dt;
      feverActive.value = true;
      backdrop.feverActive = true;
      backdrop.feverIntensity = 1.35;
      for (final h in children.whereType<Hazard>()) {
        h.feverBreath = math.sin(_runTime * 6) * 0.5 + 0.5;
      }
      if (_feverTimer <= 0) {
        feverActive.value = false;
        backdrop.feverActive = false;
        backdrop.feverIntensity = 1.0;
      }
    } else {
      feverActive.value = false;
      backdrop.feverActive = false;
      backdrop.feverIntensity = 1.0;
    }

    final wasCollapsed = player.isCollapsed;
    formLabel.value = player.isCollapsed ? 'SLIM' : 'SMASH';

    if (_fingerDown && !_suppressHold) {
      _holdTimer += dt;
      if (_holdTimer >= 0.12) setCollapse(true);
      holdRemain.value = (_holdTimer < 0.12 ? (0.12 - _holdTimer) : 0.0)
          .clamp(0.0, 0.12)
          .toDouble();
    } else {
      holdRemain.value = 0;
    }

    if (player.isCollapsed && !wasCollapsed) PulseSfx.slimTick();

    score.value += (worldSpeed * 120 * dt).round();
    _updateCoinMultiplier();

    final tier = (meters.value ~/ 25).clamp(0, 12);
    if (tier > _lastTier && !_tutorial) {
      _lastTier = tier;
      speedTier.value = tier;
      add(
        FloatingText(
          at: Vector2(size.x * 0.5, size.y * 0.2),
          text: 'SPEED UP',
          color: PulseColors.coin,
        ),
      );
      HapticFeedback.mediumImpact();
    }

    if (!_feverTimeUsed && _runTime > 28 && _feverTimer <= 0) {
      _feverTimeUsed = true;
      _startFever(label: 'PULSE FEVER');
    }

    if (_tutorial) {
      _runTutorial();
    } else {
      while (_beatAcc >= PulseConfig.beatInterval) {
        _beatAcc -= PulseConfig.beatInterval;
        PulseSfx.beatPulse();
        _spawnTimer += PulseConfig.beatInterval;
        if (_spawnTimer >= _nextSpawn) {
          _spawnTimer = 0;
          _nextSpawn = _feverTimer > 0
              ? PulseConfig.beatInterval * 0.85
              : _spawnGapForPhase();
          _spawnRhythmPattern();
        }
      }
    }

    final step = worldSpeed * dt;
    for (final h in children.whereType<Hazard>().toList()) {
      h.advance(step);
      h.checkAgainst(player);
    }
  }

  void _updateCoinMultiplier() {
    var mult = 1.0;
    if (_formStreakVal >= 5) mult = 1.5;
    if (_feverTimer > 0) mult *= 2.0;
    coinMultiplier.value = mult;
  }

  void _setHauntTip() {
    final h = _progress.pendingHaunt.value;
    if (h == null || _tutorial) {
      hauntLabel.value = '';
      return;
    }
    hauntLabel.value = h.power > 1
        ? '👻 ${h.name} · сила x${h.power}'
        : '👻 ${h.name}';
    if (_everFinishedTutorial) {
      tip.value = 'Призрак на ~$_hauntSpawnMeter m — отомсти!';
    }
  }

  void _trySpawnHaunt(int m) {
    if (_hauntSpawned || _tutorial || isGameOver) return;
    final record = _progress.pendingHaunt.value;
    if (record == null) return;
    if (m < _hauntSpawnMeter) return;
    _hauntSpawned = true;
    _spawnHaunt(record);
  }

  void _spawnHaunt(HauntRecord record) {
    tip.value = '';
    add(
      FloatingText(
        at: Vector2(size.x * 0.5, size.y * 0.18),
        text: 'ПРИЗРАК',
        color: const Color(0xFFB388FF),
      ),
    );
    _addHazard(
      record.hazardKind,
      [record.lane.clamp(0, 2)],
      isHaunt: true,
      hauntPower: record.power,
    );
    PulseSfx.beatPulse();
  }

  void _onHauntCaptured(Hazard h) {
    _completeHauntCapture(h);
  }

  Future<void> _completeHauntCapture(Hazard h) async {
    final reward = await _progress.captureHaunt(atMeters: meters.value);
    runCoins.value += reward;
    hauntLabel.value = '';
    tip.value = '';
    PulseSfx.hauntCaptured();
    add(
      FloatingText(
        at: player.position + Vector2(0, -50),
        text: 'ПОЙМАН! +$reward 🪙',
        color: const Color(0xFFE1BEE7),
      ),
    );
    add(BurstFx(at: h.position.clone(), color: const Color(0xFFB388FF), count: 22));
    _registerPerfectForm(label: 'REVENGE');
    HapticFeedback.heavyImpact();
  }

  void _checkStation(int m) {
    if (m < _nextStationAt) return;
    _nextStationAt += PulseConfig.stationDistance;
    toStation.value = _nextStationAt - m;
    stationsThisRun.value += 1;
    lastStationBonus = 25 + stationsThisRun.value * 10;
    _awardCoins(lastStationBonus);
    _progress.addStation();
    PulseSfx.station();
    stationToast.value =
        'СТАНЦИЯ #${stationsThisRun.value} · +$lastStationBonus 🪙';
    _stationToastTimer = 1.2;
    _shake.bang(6, duration: 0.12);
  }

  void _recordGhost() {
    _ghostSampleAcc += 1;
    if (_ghostSampleAcc < 3) return;
    _ghostSampleAcc = 0;
    _ghostRecording.add(
      _GhostPoint(player.laneBlend, player.position.y),
    );
    if (_ghostRecording.length > 80) _ghostRecording.removeAt(0);
  }

  double _spawnGapForPhase() {
    if (_riskyNextPattern) return 0.38;
    final phase = _phase();
    return switch (phase) {
      0 => 1.1,
      1 => 0.85,
      2 => 0.65,
      _ => 0.48,
    };
  }

  void _startFever({required String label}) {
    if (_feverTimer > 0) return;
    _feverTimer = 15;
    PulseSfx.fever();
    add(
      FloatingText(
        at: Vector2(size.x * 0.5, size.y * 0.28),
        text: label,
        color: PulseColors.gate,
      ),
    );
    HapticFeedback.heavyImpact();
  }

  void _runTutorial() {
    if (_tutStep == 0 && _runTime > 1.2) {
      _tutStep = 1;
      tip.value = 'СВАЙП ← → от красного ✕';
      _addHazard(HazardKind.wall, [1]);
    } else if (_tutStep == 1 && _runTime > 4.0) {
      _tutStep = 2;
      tip.value = 'УДЕРЖИ — slim в щель HOLD';
      _addHazard(HazardKind.gate, [player.lane]);
    } else if (_tutStep == 2 && _runTime > 7.2) {
      _tutStep = 3;
      tip.value = 'ОТПУСТИ — smash стекло';
      _addHazard(HazardKind.brittle, [player.lane]);
    } else if (_tutStep == 3 && _runTime > 10.4) {
      _tutStep = 4;
      tip.value = 'PERFECT FORM = монеты ×1.5';
      _addHazard(HazardKind.wall, [0]);
      _addCollectible([1]);
    } else if (_tutStep == 4 && _runTime > 13.5) {
      _tutorial = false;
      _everFinishedTutorial = true;
      tip.value = '';
      _beatAcc = 0;
      add(
        FloatingText(
          at: Vector2(size.x * 0.5, size.y * 0.24),
          text: 'GO!',
          color: PulseColors.pulse,
        ),
      );
    }
  }

  void _spawnRhythmPattern() {
    if (_feverTimer > 0) {
      _spawnFeverPattern();
      return;
    }

    final phase = _phase();
    _patternBeat = (_patternBeat + 1) % 11;

    if (phase == 0) {
      if (_patternBeat.isOdd) return;
      _addCollectible([_dailyRng.nextInt(3)]);
      return;
    }

    if (_riskyNextPattern) {
      _riskyNextPattern = false;
      final lane = _dailyRng.nextInt(3);
      _addHazard(HazardKind.wall, [(lane + 1) % 3]);
      _addHazard(HazardKind.brittle, [lane], depthOff: -0.05);
      _addHazard(HazardKind.gate, [(lane + 2) % 3], depthOff: -0.08);
      return;
    }

    switch (_patternBeat) {
      case 0:
        _addHazard(HazardKind.wall, [_dailyRng.nextInt(3)]);
      case 1:
        _spawnCollectibleBurst();
      case 2:
        _addHazard(HazardKind.brittle, [_dailyRng.nextInt(3)]);
      case 3:
        _addHazard(HazardKind.gate, [_dailyRng.nextInt(3)]);
      case 4:
        _spawnComboLaneForm();
      case 5:
        _addHazard(HazardKind.gate, [1]);
        _addCollectible([0], depthOff: -0.04);
        _addCollectible([2], depthOff: -0.04);
      case 6:
        final a = _dailyRng.nextInt(3);
        _addHazard(HazardKind.wall, [a]);
        _addCollectible([(a + 1) % 3]);
        _addHazard(HazardKind.brittle, [(a + 2) % 3], depthOff: -0.06);
      case 7:
        if (phase >= 2) {
          final lane = _dailyRng.nextInt(3);
          _addHazard(HazardKind.wall, [(lane + 1) % 3, (lane + 2) % 3]);
          _addCollectible([lane]);
          _addHazard(HazardKind.gate, [lane], depthOff: -0.08);
        } else {
          _spawnCollectibleBurst();
        }
      case 8:
        _spawnPulseGate();
      case 9:
        _spawnCrystalCorridor();
      case 10:
        _spawnFakeLane();
    }
  }

  void _spawnFeverPattern() {
    feverHits.value += 1;
    final alt = feverHits.value.isOdd;
    if (alt) {
      _addHazard(HazardKind.gate, [_dailyRng.nextInt(3)]);
    } else {
      _addHazard(HazardKind.brittle, [_dailyRng.nextInt(3)]);
    }
    if (feverHits.value % 3 == 0) {
      _addCollectible([_dailyRng.nextInt(3)], depthOff: -0.04);
    }
  }

  void _spawnComboLaneForm() {
    final safe = _dailyRng.nextInt(3);
    _addHazard(HazardKind.wall, <int>[0, 1, 2]..remove(safe));
    _addHazard(HazardKind.gate, [safe], depthOff: -0.02);
    tip.value = 'СВАЙП + HOLD';
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (started.value && !isGameOver) tip.value = '';
    });
  }

  void _spawnPulseGate() {
    final lane = _dailyRng.nextInt(3);
    _addHazard(HazardKind.gate, [lane], depthOff: 0);
    _addHazard(HazardKind.brittle, [lane], depthOff: -0.05);
    _addHazard(HazardKind.gate, [lane], depthOff: -0.1);
  }

  void _spawnCrystalCorridor() {
    _addHazard(HazardKind.brittle, [0]);
    _addHazard(HazardKind.brittle, [1], depthOff: -0.04);
    _addHazard(HazardKind.brittle, [2], depthOff: -0.08);
    if (_phase() >= 2) {
      _addHazard(HazardKind.wall, [0], depthOff: -0.12);
      _addHazard(HazardKind.wall, [2], depthOff: -0.12);
    }
  }

  void _spawnFakeLane() {
    final trap = _dailyRng.nextInt(3);
    _addCollectible([trap], depthOff: -0.02);
    _addHazard(HazardKind.fakeWall, [trap], depthOff: -0.05);
  }

  void _spawnCollectibleBurst() {
    final kinds = CollectibleKind.values;
    final lanes = <int>{};
    final count = 2 + _rng.nextInt(2);
    while (lanes.length < count) {
      lanes.add(_dailyRng.nextInt(3));
    }
    var i = 0;
    for (final lane in lanes) {
      _addCollectible(
        [lane],
        kind: kinds[(i + _rng.nextInt(2)) % kinds.length],
        depthOff: -0.03 * i,
      );
      i++;
    }
    if (_phase() >= 1 && _rng.nextDouble() > 0.55) {
      _addBoost([_dailyRng.nextInt(3)], depthOff: -0.06);
    }
  }

  void _addBoost(List<int> lanes, {double depthOff = 0}) {
    final h = Hazard(
      space: space,
      kind: HazardKind.boost,
      lanes: lanes,
      onPassed: _onPassed,
      onHit: _onHit,
      onNearMiss: _onNearMiss,
      onShard: _onShard,
      onSmash: _onSmash,
      onFormWarn: _onFormWarn,
      onBoost: _onBoost,
    );
    if (depthOff != 0) h.depth = PulseConfig.spawnDepth + depthOff;
    add(h);
  }

  void _addCollectible(
    List<int> lanes, {
    CollectibleKind? kind,
    double depthOff = 0,
  }) {
    final h = Hazard(
      space: space,
      kind: HazardKind.shard,
      lanes: lanes,
      collectible: kind ?? CollectibleKind.values[_rng.nextInt(4)],
      onPassed: _onPassed,
      onHit: _onHit,
      onNearMiss: _onNearMiss,
      onShard: _onShard,
      onSmash: _onSmash,
      onFormWarn: _onFormWarn,
    );
    if (depthOff != 0) h.depth = PulseConfig.spawnDepth + depthOff;
    add(h);
  }

  int _phase() {
    if (_runTime < 16) return 0;
    if (_runTime < 34) return 1;
    if (_runTime < 56) return 2;
    return 3;
  }

  void _addHazard(
    HazardKind kind,
    List<int> lanes, {
    double depthOff = 0,
    bool isHaunt = false,
    int hauntPower = 1,
  }) {
    final h = Hazard(
      space: space,
      kind: kind,
      lanes: lanes,
      isHaunt: isHaunt,
      hauntPower: hauntPower,
      onPassed: _onPassed,
      onHit: _onHit,
      onNearMiss: _onNearMiss,
      onShard: _onShard,
      onSmash: _onSmash,
      onFormWarn: _onFormWarn,
      onHauntCaptured: _onHauntCaptured,
    );
    if (depthOff != 0) h.depth = PulseConfig.spawnDepth + depthOff;
    add(h);
  }

  void _registerPerfectForm({String? label}) {
    _formStreakVal += 1;
    formStreak.value = _formStreakVal;
    player.correctGlow = 1;
    if (_formStreakVal > _runFormBest) {
      _runFormBest = _formStreakVal;
    }
    if (_formStreakVal > _bestFormVal) {
      _bestFormVal = _formStreakVal;
      bestFormStreak.value = _bestFormVal;
    }
    if (_formStreakVal >= 10 && _feverTimer <= 0) {
      _startFever(label: 'FEVER · FORM 10+');
    }
    if (_formStreakVal % 5 == 0) {
      _slowMoTimer = 0.45;
      add(
        FloatingText(
          at: player.position.clone(),
          text: 'PERFECT FORM x$_formStreakVal',
          color: PulseColors.pulseHot,
        ),
      );
      HapticFeedback.mediumImpact();
    } else if (label != null) {
      add(
        FloatingText(
          at: player.position + Vector2(0, -28),
          text: label,
          color: PulseColors.pulse,
        ),
      );
    }
    _updateCoinMultiplier();
  }

  void _breakFormStreak() {
    if (_formStreakVal > 0) PulseSfx.falseNote();
    _formStreakVal = 0;
    formStreak.value = 0;
    _updateCoinMultiplier();
  }

  void _onFormWarn(Hazard h) {
    _warnDecay = 0.35;
    warnFlash.value = 1;
    backdrop.warnFlash = 1;
    player.wrongOutline = 1;
    _shake.bang(4, duration: 0.08);
    HapticFeedback.lightImpact();
  }

  void _onPassed(Hazard h, {required bool perfect}) {
    _smashStreakRun = 0;
    combo.value += 1;
    final mult = (1 + combo.value ~/ 3).clamp(1, 8);
    score.value += 40 * mult;
    if (h.kind == HazardKind.wall || h.kind == HazardKind.fakeWall) {
      _registerPerfectForm(label: 'DODGE');
    }
    if (perfect) {
      score.value += 80 * mult;
      _registerPerfectForm(label: 'SLIP');
      _shake.bang(3, duration: 0.1);
      player.correctGlow = 1;
      HapticFeedback.lightImpact();
    }
  }

  void _onSmash(Hazard h) {
    combo.value += 2;
    _smashStreakRun += 1;
    if (_smashStreakRun > _runSmashBest) _runSmashBest = _smashStreakRun;
    final mult = (1 + combo.value ~/ 3).clamp(1, 9);
    score.value += 140 * mult;
    _registerPerfectForm(label: 'SMASH');
    _shake.bang(8, duration: 0.16);
    add(BurstFx(at: h.position.clone(), color: PulseColors.smash, count: 18));
    PulseSfx.smashHit();
    HapticFeedback.mediumImpact();
  }

  void _onNearMiss(Hazard h) {
    final mult = (1 + combo.value ~/ 3).clamp(1, 8);
    score.value += 70 * mult;
    combo.value += 1;
    closeCount.value += 1;
    _shake.bang(5, duration: 0.12);
    add(
      FloatingText(
        at: player.position + Vector2(0, -34),
        text: 'CLOSE!',
        color: PulseColors.pulseHot,
      ),
    );
    PulseSfx.close();
  }

  void _onBoost(Hazard h) {
    _boostTimer = 4;
    _riskyNextPattern = true;
    _awardCoins(8, label: 'BOOST');
    PulseSfx.boost();
    add(
      FloatingText(
        at: h.position.clone(),
        text: 'BOOST!',
        color: PulseColors.pulse,
      ),
    );
    add(BurstFx(at: h.position.clone(), color: PulseColors.pulse, count: 14));
  }

  int _coinValue(CollectibleKind kind) => switch (kind) {
        CollectibleKind.orb => 3,
        CollectibleKind.ring => 4,
        CollectibleKind.bolt => 5,
        CollectibleKind.prism => 4,
      };

  void _awardCoins(int base, {String? label}) {
    final earned = (base * coinMultiplier.value).round();
    runCoins.value += earned;
    _progress.addCoins(earned);
    if (label != null) {
      add(
        FloatingText(
          at: player.position + Vector2(0, -40),
          text: '+$earned 🪙',
          color: PulseColors.coinGlow,
        ),
      );
    }
    PulseSfx.coin();
  }

  void _onShard(Hazard h) {
    _smashStreakRun = 0;
    combo.value += 1;
    final mult = (1 + combo.value ~/ 3).clamp(1, 8);
    final bonus = switch (h.collectible) {
      CollectibleKind.orb => 90,
      CollectibleKind.ring => 110,
      CollectibleKind.bolt => 130,
      CollectibleKind.prism => 100,
    };
    final label = switch (h.collectible) {
      CollectibleKind.orb => 'ORB',
      CollectibleKind.ring => 'RING',
      CollectibleKind.bolt => 'BOLT',
      CollectibleKind.prism => 'PRISM',
    };
    score.value += bonus * mult;
    _registerPerfectForm(label: label);
    _awardCoins(_coinValue(h.collectible));
    add(BurstFx(at: h.position.clone(), color: PulseColors.coinGlow, count: 12));
    add(
      FloatingText(
        at: h.position.clone(),
        text: label,
        color: PulseColors.coinGlow,
      ),
    );
    HapticFeedback.lightImpact();
  }

  bool _dailyMet() {
    final g = _progress.dailyGoal;
    return switch (g.type) {
      DailyGoalType.reachMeters => meters.value >= g.target,
      DailyGoalType.smashStreak => _runSmashBest >= g.target,
      DailyGoalType.formStreak => _runFormBest >= g.target,
    };
  }

  void _onHit(Hazard h) {
    if (isGameOver) return;
    _deathHazard = h;
    _breakFormStreak();
    combo.value = 0;
    _deathFlash = 0.45;
    failReason.value = switch (h.kind) {
      HazardKind.wall => h.isHaunt
          ? 'Призрак ✕ — свайп, отомсти!'
          : 'Красный ✕ — свайп в другую полосу',
      HazardKind.fakeWall => h.isHaunt
          ? 'Призрак-ловушка вернулся'
          : 'Ловушка! Полоса казалась безопасной',
      HazardKind.gate => h.isHaunt
          ? 'Призрак HOLD — удержи и сожмись'
          : 'Щель HOLD — удержи и сожмись',
      HazardKind.brittle => h.isHaunt
          ? 'Призрак SMASH — отпусти палец'
          : 'Стекло SMASH — отпусти палец',
      HazardKind.shard => 'Столкновение',
      HazardKind.boost => 'Столкновение',
    };
    if (h.isHaunt) {
      PulseSfx.hauntLaugh();
      tip.value = 'Призрак смеётся... сильнее в след. забеге';
    }
    _shake.bang(18, duration: 0.42);
    add(BurstFx(at: player.position.clone(), color: PulseColors.hazard, count: 28));
    PulseSfx.die();

    if (!_secondChanceUsed) {
      _secondChanceUsed = true;
      secondChanceOffer.value = true;
      isGameOver = true;
      overlays.add(PulseConfig.continueRun);
      return;
    }

    _finalizeGameOver();
  }

  void _finalizeGameOver() {
    isGameOver = true;
    if (score.value > best.value) best.value = score.value;
    if (meters.value > bestMeters.value) {
      bestMeters.value = meters.value;
      if (_ghostRecording.length > 10) {
        _bestGhost
          ..clear()
          ..addAll(_ghostRecording);
      }
    }

    _progress.recordRun(
      meters: meters.value,
      formStreak: _runFormBest,
      closeCount: closeCount.value,
      dailyMet: _dailyMet(),
    );

    final dh = _deathHazard;
    if (dh != null && _everFinishedTutorial) {
      _progress.registerDeath(
        kind: dh.kind,
        lane: dh.lanes.first,
        meters: meters.value,
        killedByHaunt: dh.isHaunt,
      );
    }

    overlays.remove(PulseConfig.input);
    overlays.remove(PulseConfig.hud);
    overlays.remove(PulseConfig.continueRun);
    overlays.add(PulseConfig.gameOver);
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (isGameOver && !secondChanceOffer.value) pauseEngine();
    });
  }

  String get shareCardLine => _progress.shareLine(
        meters: meters.value,
        form: _runFormBest,
        close: closeCount.value,
        haunts: _progress.capturedHauntCount.value,
      );

  int get metersFromRecord => _progress.metersFromRecord(meters.value);

  Future<void> buySkin(String skinId, int cost) =>
      _progress.buySkin(skinId, cost);

  Future<void> selectSkin(String skinId) => _progress.selectSkin(skinId);

  bool isSkinUnlocked(String id) => _progress.isUnlocked(id);

  PulseProgress get progress => _progress;

  @override
  void render(Canvas canvas) {
    _drawGhost(canvas);
    if (_shakeOff != Offset.zero) {
      canvas.save();
      canvas.translate(_shakeOff.dx, _shakeOff.dy);
    }
    super.render(canvas);
    if (_shakeOff != Offset.zero) canvas.restore();

    if (_deathFlash > 0) {
      canvas.drawRect(
        Offset.zero & size.toSize(),
        Paint()
          ..color = PulseColors.hazard
              .withValues(alpha: (0.35 * (_deathFlash / 0.45)).clamp(0, 0.4)),
      );
    }
  }

  void _drawGhost(Canvas canvas) {
    if (_bestGhost.isEmpty || !started.value) return;
    final paint = Paint()
      ..color = PulseColors.pulse.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (final p in _bestGhost) {
      final x = space.laneX(p.lane.round().clamp(0, 2), PulseConfig.playerDepth);
      canvas.drawCircle(Offset(x, p.y), 6, paint);
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isDown = event is KeyDownEvent;
    final isUp = event is KeyUpEvent;

    if (isDown) {
      if (!started.value || isGameOver) {
        if (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          startRun();
          return KeyEventResult.handled;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        nudgeLane(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        nudgeLane(1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        setCollapse(true);
        return KeyEventResult.handled;
      }
    }
    if (isUp) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        setCollapse(false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _clearHazards() {
    children.whereType<Hazard>().toList().forEach((h) => h.removeFromParent());
    children.whereType<BurstFx>().toList().forEach((c) => c.removeFromParent());
    children
        .whereType<FloatingText>()
        .toList()
        .forEach((c) => c.removeFromParent());
  }
}
