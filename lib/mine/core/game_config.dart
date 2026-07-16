/// Global tuning for Mine Slice Runner.
abstract final class GameConfig {
  static const targetFps = 60.0;

  /// Fixed world size — resolution/aspect only letterboxes; world never jumps.
  static const worldWidth = 1280.0;
  static const worldHeight = 720.0;

  /// One invisible ground line forever. Miner / spikes / landings use this.
  /// Background art is only decoration aligned to this Y.
  static const groundY = 460.0;

  /// Miner feet X in world space (never depends on window size).
  static const minerX = 280.0;

  /// Red GroundY line + green feet circle. Off after calibration.
  static const debugGround = false;

  /// Base meters/sec — ramps up with distance via DifficultyManager.speedScale.
  static const metersPerSecond = 12.0;

  /// New background every N meters (crossfade at segment start).
  static const biomeIntervalMeters = 600.0;

  /// Dual-layer crossfade duration (smoothstep).
  static const biomeFadeSeconds = 1.25;

  /// Normalized render targets (auto-scale any asset to these heights).
  static const minerTargetHeight = 168.0;
  static const rockSmallHeight = 68.0;
  static const rockMediumHeight = 104.0;
  static const rockLargeHeight = 140.0;
  static const spiderTargetHeight = 72.0;
  static const bossSpiderTargetHeight = 140.0;

  /// Steady run cycle — slower hold per frame = smoother legs.
  static const runCycleSeconds = 1.32;

  /// No camera bob — feet stay treadmill-stable on the path.
  static const runBobAmpX = 0.0;
  static const runBobAmpY = 0.0;
  static const runBobPeriod = 0.44;

  /// Background scroll at base speed (× speedScale).
  static const bgScrollSpeed = 110.0;

  /// Distance ramp: reaches max earlier so speed-up is obvious.
  static const speedRampMeters = 1000.0;
  static const speedScaleMax = 2.75;

  /// Slice must move at least this many px to count.
  static const minSwipeLength = 28.0;

  /// Combo thresholds.
  static const combo3 = 3;
  static const combo5 = 5;
  static const frenzy10 = 10;
  static const frenzyDuration = 4.5;

  /// Power crystal → timed swipe-slice mode.
  static const sliceModeDuration = 5.0;
  /// Finger move under this = TAP (not a slice swipe).
  static const tapMaxMove = 22.0;
  /// Generous near-miss tap — multiplier on hitRadius + flat padding.
  static const tapReachMul = 3.0;
  static const tapReachPad = 58.0;
  /// Up to 3 threats — rain feel, never a head-clump wall.
  static const maxLiveThreats = 3;
  /// Time between spawns (so they don't arrive as one horizontal wall).
  static const minSpawnGap = 1.05;
  /// Min horizontal gap between live threats (px).
  static const minLaneGapPx = 140.0;
  /// At most one dangerous faller in the miner crown corridor.
  static const maxThreatsInMinerLane = 1;

  /// ~0.5 m in world px (miner ≈ 1.7 m tall → 168 px).
  static const dynamiteDetonatePx = 50.0;

  /// Gentle mid-air correction so threats read as «falling on you».
  static const threatHomingAccel = 52.0;
  static const threatHomingVerticalMul = 0.52;
  static const stoneHomingMul = 0.55;

  /// Spawn from ceiling ahead of the miner (fraction of world width).
  static const spawnAheadMinFrac = 0.04;
  static const spawnAheadMaxFrac = 0.34;
  static const spawnAheadSpreadFrac = 0.26;
  static const spawnCeilingMinY = 150.0;
  static const spawnCeilingMaxY = 240.0;

  /// Show cyan hurt-box overlay while tuning (keep false for players).
  static const debugMinerHitbox = false;

  /// Extra pad around dwarf silhouette (px) — keep modest for fair near-misses.
  static const minerHurtPadPx = 18.0;

  static const overlayHud = 'hud';
  static const overlayGameOver = 'gameOver';
  static const overlayPause = 'pause';
  static const overlayTitle = 'title';
  static const overlayEvent = 'event';

  /// Random events — every 15–20 s at 12 m/s ≈ 180–240 m.
  static const eventFirstDelay = 14.0;
  static const eventMinInterval = 15.0;
  static const eventMaxInterval = 20.0;
  static const eventDuration = 5.5;

  /// Boss every 1000–1500 m.
  static const bossMinDistance = 1000.0;
  static const bossMaxDistance = 1500.0;

  /// Game over hit-stop before overlay.
  static const deathFreezeSeconds = 0.12;
}
