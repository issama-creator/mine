abstract final class PulseConfig {
  static const int laneCount = 3;

  /// Player sits this far into the tunnel depth [0 far → 1 near].
  static const double playerDepth = 0.82;

  /// Calm start, faster with distance.
  static const double baseSpeed = 0.32;
  static const double maxSpeed = 0.92;
  static const double metersToMaxSpeed = 130;

  /// Snappier lane switch (between buttery and instant).
  static const double laneSwitchSeconds = 0.28;

  /// Rhythm spawn — ~116 BPM.
  static const double beatInterval = 0.52;

  /// Meters gained per depth unit traveled.
  static const double metersPerDepth = 95;

  /// Collapse grow/shrink lerp speed.
  static const double collapseLerp = 14;

  /// How long before first obstacle.
  static const double spawnWarmup = 1.4;

  /// Spawn gap at start / late game (seconds between patterns).
  static const double spawnGapStart = 1.05;
  static const double spawnGapMin = 0.42;

  /// Depth where obstacles spawn (far).
  static const double spawnDepth = 0.05;

  /// Hit window around player depth.
  static const double hitDepthPad = 0.045;

  /// Near-miss depth window.
  static const double nearMissPad = 0.07;

  static const String hud = 'hud';
  static const String input = 'input';
  static const String gameOver = 'gameOver';
  static const String title = 'title';
  static const String station = 'station';
  static const String continueRun = 'continueRun';

  /// Run goal — station checkpoint distance.
  static const int stationDistance = 60;
}
