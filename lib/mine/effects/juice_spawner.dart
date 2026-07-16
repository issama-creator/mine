import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../models/object_kind.dart';
import '../components/effects/juice_effects.dart';

/// Spawns slice juice — particles, debris, popups.
abstract final class JuiceSpawner {
  static void onSlice(
    Component parent,
    Vector2 at,
    ObjectKind kind, {
    required int points,
    required bool perfect,
    required bool killed,
    required int combo,
    Sprite? sprite,
    Vector2? objectSize,
    double objectAngle = 0,
  }) {
    final pos = at.clone();
    parent.add(ImpactFlash(at: pos, maxRadius: _flashRadius(kind, killed)));

    if (killed) {
      _spawnDeath(
        parent,
        pos,
        kind,
        sprite: sprite,
        objectSize: objectSize,
        objectAngle: objectAngle,
      );
    } else {
      _spawnDamaged(parent, pos, kind);
    }

    final scoreColor = perfect
        ? const Color(0xFFFFEB3B)
        : const Color(0xFFFFFFFF);
    parent.add(
      FloatingPopup(
        at: pos + Vector2(0, -8),
        text: perfect ? '+$points PERFECT' : '+$points',
        color: scoreColor,
        glow: perfect,
      ),
    );

    if (combo >= 3 && killed) {
      final label = combo >= 10
          ? 'FRENZY!'
          : combo >= 5
              ? 'COMBO x$combo'
              : 'COMBO x$combo';
      parent.add(
        FloatingPopup(
          at: pos + Vector2(0, -36),
          text: label,
          color: combo >= 10
              ? const Color(0xFFFF5252)
              : const Color(0xFF80DEEA),
          glow: true,
          big: combo >= 5,
        ),
      );
    }
  }

  static double _flashRadius(ObjectKind kind, bool killed) {
    if (!killed) return 36;
    return switch (kind) {
      ObjectKind.dynamite || ObjectKind.objDynamite => 44,
      ObjectKind.objCrate => 52,
      ObjectKind.bossSpider => 58,
      ObjectKind.objCrystal || ObjectKind.diamond => 50,
      _ => 46,
    };
  }

  static void _spawnDamaged(Component parent, Vector2 at, ObjectKind kind) {
    if (kind == ObjectKind.bossSpider) {
      parent.add(
        ParticleBurst(
          at: at.clone(),
          colors: const [Color(0xFFFF5252), Color(0xFFFF8A80)],
          count: 8,
          speed: 90,
        ),
      );
      parent.add(
        FloatingPopup(
          at: at.clone() + Vector2(0, -20),
          text: 'CRACK!',
          color: const Color(0xFFFF8A80),
        ),
      );
    }
  }

  static void _spawnDeath(
    Component parent,
    Vector2 at,
    ObjectKind kind, {
    Sprite? sprite,
    Vector2? objectSize,
    double objectAngle = 0,
  }) {
    final size = objectSize ?? Vector2(kind.targetHeight, kind.targetHeight);

    switch (kind) {
      case ObjectKind.objCrate:
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -22),
            text: 'SPLIT!',
            color: const Color(0xFFFFCC80),
            glow: true,
          ),
        );
        if (sprite != null) {
          parent.add(
            SplitSpriteHalves(
              at: at,
              sprite: sprite,
              objectSize: size,
              baseAngle: objectAngle,
            ),
          );
        }
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFF8D6E63),
              Color(0xFFBCAAA4),
              Color(0xFF6D4C41),
            ],
            count: 10,
            speed: 90,
            spread: math.pi,
            baseAngle: -math.pi / 2,
            life: 0.45,
          ),
        );

      case ObjectKind.dynamite:
      case ObjectKind.objDynamite:
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -18),
            text: 'POP!',
            color: const Color(0xFFFF9800),
            glow: true,
          ),
        );
        parent.add(DynamitePop(at: at));
        parent.add(ImpactFlash(at: at.clone(), maxRadius: 38));

      case ObjectKind.rockSmall:
      case ObjectKind.rockMedium:
      case ObjectKind.rockLarge:
      case ObjectKind.objRock:
      case ObjectKind.debris:
        parent.add(
          RockCrushBurst(
            at: at,
            heavy: kind == ObjectKind.rockLarge,
            sprite: sprite,
            objectSize: size,
          ),
        );
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [Color(0xFFBCAAA4), Color(0xFF8D6E63)],
            count: 8,
            speed: 55,
            spread: math.pi,
            baseAngle: -math.pi / 2,
            life: 0.4,
          ),
        );

      case ObjectKind.objSaw:
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -16),
            text: 'ZZZT!',
            color: const Color(0xFFECEFF1),
            glow: true,
          ),
        );
        parent.add(SawSparkShower(at: at));
        if (sprite != null) {
          parent.add(
            SplitSpriteHalves(
              at: at,
              sprite: sprite,
              objectSize: size,
              baseAngle: objectAngle,
              gapSpeed: 120,
            ),
          );
        }

      case ObjectKind.objSpikeBlock:
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -16),
            text: 'CRACK!',
            color: const Color(0xFFBCAAA4),
          ),
        );
        parent.add(SpikeBreakBurst(at: at));
        if (sprite != null) {
          parent.add(
            SplitSpriteHalves(
              at: at,
              sprite: sprite,
              objectSize: size,
              baseAngle: objectAngle,
              gapSpeed: 130,
            ),
          );
        }

      case ObjectKind.diamond:
      case ObjectKind.objCrystal:
        parent.add(CrystalShatterRing(at: at));
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -20),
            text: 'SHINE!',
            color: const Color(0xFF80DEEA),
            glow: true,
          ),
        );

      case ObjectKind.goldNugget:
        parent.add(CrystalShatterRing(at: at, golden: true));
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -18),
            text: 'COIN!',
            color: const Color(0xFFFFD54F),
            glow: true,
          ),
        );

      case ObjectKind.spider:
        parent.add(SpiderSplat(at: at));
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -14),
            text: 'SPLAT!',
            color: const Color(0xFF7CB342),
          ),
        );

      case ObjectKind.bossSpider:
        parent.add(SpiderSplat(at: at, big: true));
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFFFF5252),
              Color(0xFF7CB342),
              Color(0xFF33691E),
            ],
            count: 20,
            speed: 170,
          ),
        );

      case ObjectKind.woodBeam:
        parent.add(WoodSplinterBurst(at: at));
        parent.add(
          FloatingPopup(
            at: at + Vector2(0, -14),
            text: 'SPLIT!',
            color: const Color(0xFFBCAAA4),
          ),
        );

      case ObjectKind.stalactite:
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFFB0BEC5),
              Color(0xFF78909C),
              Color(0xFFE0F7FA),
            ],
            count: 16,
            speed: 150,
          ),
        );
        for (var i = 0; i < 3; i++) {
          final ang = -math.pi / 2 + (math.Random().nextDouble() - 0.5);
          parent.add(
            DebrisShard(
              at: at.clone(),
              velocity: Vector2(
                math.cos(ang) * 130,
                math.sin(ang) * 130,
              ),
              color: const Color(0xFF78909C),
              shardSize: 10,
            ),
          );
        }

      case ObjectKind.pathSpike:
        parent.add(SpikeBreakBurst(at: at));
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFF8D6E63),
              Color(0xFF5D4037),
              Color(0xFFBCAAA4),
            ],
            count: 12,
            speed: 110,
            baseAngle: -math.pi / 2,
            spread: math.pi,
          ),
        );
    }
  }

  /// Small localized burst when a threat hits the miner.
  static void onMinerHit(Component parent, Vector2 at, ObjectKind kind) {
    final impact = at.clone();

    parent.add(ImpactFlash(at: impact, maxRadius: 34));

    switch (kind) {
      case ObjectKind.dynamite:
      case ObjectKind.objDynamite:
        parent.add(DynamitePop(at: impact));
        parent.add(ImpactFlash(at: impact.clone(), maxRadius: 48));
      case ObjectKind.spider:
      case ObjectKind.bossSpider:
        parent.add(SpiderSplat(at: impact, big: kind == ObjectKind.bossSpider));
      case ObjectKind.pathSpike:
        parent.add(SpikeBreakBurst(at: impact));
      case ObjectKind.stalactite:
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [
              Color(0xFFB0BEC5),
              Color(0xFF78909C),
              Color(0xFFE0F7FA),
            ],
            count: 10,
            speed: 85,
            life: 0.4,
          ),
        );
      case ObjectKind.rockSmall:
      case ObjectKind.rockMedium:
      case ObjectKind.rockLarge:
      case ObjectKind.objRock:
      case ObjectKind.debris:
        parent.add(RockCrushBurst(at: impact));
      case ObjectKind.objCrate:
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [
              Color(0xFF8D6E63),
              Color(0xFFBCAAA4),
              Color(0xFF6D4C41),
            ],
            count: 10,
            speed: 80,
            life: 0.4,
          ),
        );
      default:
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [
              Color(0xFF90A4AE),
              Color(0xFFBCAAA4),
              Color(0xFF8D6E63),
            ],
            count: 8,
            speed: 70,
            spread: math.pi,
            life: 0.38,
          ),
        );
    }
  }

  /// Missed object smashes into the stone path — sand / crumb puff (~0.5s).
  static void onGroundHit(Component parent, Vector2 at, ObjectKind kind) {
    final impact = at.clone();
    parent.add(GroundSandPuff(at: impact, kind: kind));

    final colors = switch (kind) {
      ObjectKind.spider || ObjectKind.bossSpider => const [
          Color(0xFF8D6E63),
          Color(0xFF7CB342),
          Color(0xFFBCAAA4),
        ],
      ObjectKind.diamond || ObjectKind.objCrystal => const [
          Color(0xFF80DEEA),
          Color(0xFFB0BEC5),
          Color(0xFFD7CCC8),
        ],
      ObjectKind.goldNugget => const [
          Color(0xFFFFD54F),
          Color(0xFFBCAAA4),
          Color(0xFF8D6E63),
        ],
      ObjectKind.dynamite || ObjectKind.objDynamite => const [
          Color(0xFFFF8A65),
          Color(0xFF8D6E63),
          Color(0xFFBCAAA4),
        ],
      ObjectKind.objCrate => const [
          Color(0xFF8D6E63),
          Color(0xFF6D4C41),
          Color(0xFFBCAAA4),
        ],
      _ => const [
          Color(0xFFA1887F),
          Color(0xFFD7CCC8),
          Color(0xFF6D4C41),
          Color(0xFFBCAAA4),
        ],
    };

    parent.add(
      ParticleBurst(
        at: impact,
        colors: colors,
        count: kind == ObjectKind.rockLarge ? 16 : 11,
        speed: 95,
        spread: math.pi * 0.95,
        baseAngle: -math.pi / 2,
        life: 0.5,
      ),
    );
    parent.add(
      ParticleBurst(
        at: impact,
        colors: const [Color(0xFFD7CCC8), Color(0xFFBCAAA4)],
        count: 8,
        speed: 40,
        spread: math.pi,
        baseAngle: -math.pi / 2,
        life: 0.55,
      ),
    );

    if (kind == ObjectKind.rockMedium ||
        kind == ObjectKind.rockLarge ||
        kind == ObjectKind.debris ||
        kind == ObjectKind.objRock) {
      parent.add(RockCrushBurst(at: impact, heavy: kind == ObjectKind.rockLarge));
    }
    if (kind == ObjectKind.objCrate) {
      parent.add(WoodSplinterBurst(at: impact));
    }
  }
}
