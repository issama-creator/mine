import '../core/game_config.dart';

/// Three scrolling mine backgrounds — cycle every [GameConfig.biomeIntervalMeters].
///
/// Each PNG may have its painted bridge at a slightly different vertical
/// fraction. [roadOffsets] shifts that decoration so the bridge top sits on
/// [GameConfig.groundY]. Gameplay never reads these values.
abstract final class MineBackground {
  static const paths = [
    'backgr/mine_01.png',
    'backgr/mine_02.png',
    'backgr/mine_03.png',
  ];

  static const labels = [
    'Classic Mine',
    'Crystal Depths',
    'Ancient Cavern',
  ];

  /// Distance from top of a full-height stretch to the painted bridge surface.
  /// Calibrated once per art file so boots sit on the cobbles.
  static const roadOffsets = [
    486.0, // mine_01 — bridge top ≈ 67.5% of art height
    501.0, // mine_02
    510.0, // mine_03
  ];

  static int get count => paths.length;

  static int indexAtDistance(double meters) {
    final seg = (meters / GameConfig.biomeIntervalMeters).floor();
    return seg % paths.length;
  }

  static String labelAtDistance(double meters) =>
      labels[indexAtDistance(meters)];

  static String pathAtIndex(int index) => paths[index % paths.length];

  static double roadOffsetAt(int index) =>
      roadOffsets[index % roadOffsets.length];
}
