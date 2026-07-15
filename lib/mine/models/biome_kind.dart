import '../core/game_config.dart';
import 'mine_background.dart';

enum BiomeKind {
  classicMine,
  crystalCave,
  goldenMine,
  abandonedMine,
  lavaCave,
  ancientRuins,
}

/// Linear biomes for the first 6 segments, then rotation.
BiomeKind biomeAtDistance(double meters) {
  const order = BiomeKind.values;
  final index =
      (meters / GameConfig.biomeIntervalMeters).floor().clamp(0, 999999);
  if (index < order.length) return order[index];
  final idx = (index * 7919 + 13) % order.length;
  return order[idx];
}

extension BiomeKindX on BiomeKind {
  String get label => switch (this) {
        BiomeKind.classicMine => 'Classic Mine',
        BiomeKind.crystalCave => 'Crystal Cave',
        BiomeKind.goldenMine => 'Golden Mine',
        BiomeKind.abandonedMine => 'Abandoned Mine',
        BiomeKind.lavaCave => 'Lava Cave',
        BiomeKind.ancientRuins => 'Ancient Ruins',
      };

  String get bgAsset => switch (this) {
        BiomeKind.classicMine => MineBackground.paths[0],
        BiomeKind.crystalCave => MineBackground.paths[1],
        BiomeKind.goldenMine => MineBackground.paths[2],
        BiomeKind.abandonedMine => MineBackground.paths[0],
        BiomeKind.lavaCave => MineBackground.paths[1],
        BiomeKind.ancientRuins => MineBackground.paths[2],
      };
}
