/// Falling / ground object types.
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
  stalactite,
  pathSpike,
  /// PNG obstacles from assets/objekts/
  objRock,
  objCrate,
  objCrystal,
  objDynamite,
  objSaw,
  objSpikeBlock,
}

extension ObjectKindX on ObjectKind {
  bool get isDangerous => switch (this) {
        ObjectKind.diamond ||
        ObjectKind.goldNugget ||
        ObjectKind.objCrystal =>
          false,
        _ => true,
      };

  bool get isSliceCrystal => this == ObjectKind.diamond || this == ObjectKind.objCrystal;

  bool get isGroundHazard => this == ObjectKind.pathSpike;

  bool get isStalactite => this == ObjectKind.stalactite;

  bool get isObjekt => objektKinds.contains(this);

  int get maxHp => switch (this) {
        ObjectKind.bossSpider => 2,
        ObjectKind.rockLarge || ObjectKind.objCrate => 2,
        _ => 1,
      };

  int get baseScore => switch (this) {
        ObjectKind.goldNugget => 25,
        ObjectKind.diamond || ObjectKind.objCrystal => 40,
        ObjectKind.dynamite || ObjectKind.objDynamite => 35,
        ObjectKind.bossSpider => 80,
        ObjectKind.spider => 18,
        ObjectKind.rockLarge || ObjectKind.objCrate => 14,
        ObjectKind.objSaw => 22,
        _ => 10,
      };

  double get targetHeight => switch (this) {
        ObjectKind.rockSmall => 50,
        ObjectKind.rockMedium => 56,
        ObjectKind.rockLarge => 62,
        ObjectKind.bossSpider => 110,
        ObjectKind.spider => 72,
        ObjectKind.diamond || ObjectKind.objCrystal => 58,
        ObjectKind.goldNugget => 52,
        ObjectKind.dynamite || ObjectKind.objDynamite => 62,
        ObjectKind.woodBeam => 48,
        ObjectKind.debris => 44,
        ObjectKind.stalactite => 88,
        ObjectKind.pathSpike => 44,
        ObjectKind.objRock => 56,
        ObjectKind.objCrate => 90,
        ObjectKind.objSaw => 76,
        ObjectKind.objSpikeBlock => 70,
      };
}

/// All PNG objekts that fall from the sky.
const objektKinds = [
  ObjectKind.objRock,
  ObjectKind.objCrate,
  ObjectKind.objCrystal,
  ObjectKind.objDynamite,
  ObjectKind.objSaw,
  ObjectKind.objSpikeBlock,
];
