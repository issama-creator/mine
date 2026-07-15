enum ObjectKind {
  rockSmall,
  rockMedium,
  rockLarge,
  diamond,
  goldNugget,
  spider,
  bossSpider,
  dynamite,
  woodBeam,
  debris,
  /// Jagged ceiling ice/stone — falls tip-down (procedural).
  stalactite,
  /// Spikes on the path ahead of the miner (procedural).
  pathSpike,
}

extension ObjectKindX on ObjectKind {
  bool get isDangerous => switch (this) {
        ObjectKind.diamond || ObjectKind.goldNugget => false,
        _ => true,
      };

  /// Blue crystal — tap/slice it to unlock 5s swipe-slice mode.
  bool get isSliceCrystal => this == ObjectKind.diamond;

  bool get isBoss => this == ObjectKind.bossSpider;

  /// Hazard sitting on the road, scrolls toward the miner.
  bool get isGroundHazard => this == ObjectKind.pathSpike;

  /// Fast drop from ceiling.
  bool get isStalactite => this == ObjectKind.stalactite;

  int get baseScore => switch (this) {
        ObjectKind.rockSmall => 10,
        ObjectKind.rockMedium => 20,
        ObjectKind.rockLarge => 35,
        ObjectKind.diamond => 100,
        ObjectKind.goldNugget => 150,
        ObjectKind.spider => 40,
        ObjectKind.bossSpider => 200,
        ObjectKind.dynamite => 60,
        ObjectKind.woodBeam => 25,
        ObjectKind.debris => 15,
        ObjectKind.stalactite => 30,
        ObjectKind.pathSpike => 25,
      };

  int get maxHp => switch (this) {
        ObjectKind.bossSpider => 2,
        _ => 1,
      };

  double get targetHeight => switch (this) {
        ObjectKind.rockSmall => 68,
        ObjectKind.rockMedium => 104,
        ObjectKind.rockLarge => 140,
        ObjectKind.spider => 72,
        ObjectKind.bossSpider => 140,
        ObjectKind.diamond => 48,
        ObjectKind.goldNugget => 44,
        ObjectKind.dynamite => 52,
        ObjectKind.woodBeam => 40,
        ObjectKind.debris => 42,
        ObjectKind.stalactite => 90,
        ObjectKind.pathSpike => 44,
      };
}
