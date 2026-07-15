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
  }) {
    parent.add(ImpactFlash(at: at.clone()));

    if (killed) {
      _spawnDeath(parent, at, kind);
    } else if (kind == ObjectKind.bossSpider) {
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

    final scoreColor = perfect
        ? const Color(0xFFFFEB3B)
        : const Color(0xFFFFFFFF);
    parent.add(
      FloatingPopup(
        at: at.clone() + Vector2(0, -8),
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
          at: at.clone() + Vector2(0, -36),
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

  static void _spawnDeath(Component parent, Vector2 at, ObjectKind kind) {
    switch (kind) {
      case ObjectKind.rockSmall:
      case ObjectKind.rockMedium:
      case ObjectKind.rockLarge:
        _rockBurst(parent, at, kind);
      case ObjectKind.spider:
      case ObjectKind.bossSpider:
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFF7CB342),
              Color(0xFF33691E),
              Color(0xFF8D6E63),
            ],
            count: 16,
            speed: 160,
          ),
        );
      case ObjectKind.diamond:
      case ObjectKind.goldNugget:
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFF80DEEA),
              Color(0xFFFFD54F),
              Colors.white,
            ],
            count: 18,
            speed: 130,
            spread: math.pi * 2,
          ),
        );
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFFE1F5FE),
              Color(0xFFFFECB3),
            ],
            count: 10,
            speed: 55,
            spread: math.pi * 2,
            life: 0.9,
          ),
        );
      case ObjectKind.dynamite:
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFFFF5722),
              Color(0xFFFF9800),
              Color(0xFF424242),
            ],
            count: 22,
            speed: 200,
            spread: math.pi * 2,
          ),
        );
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFF90A4AE),
              Color(0xFF546E7A),
              Color(0xFF37474F),
            ],
            count: 14,
            speed: 70,
            spread: math.pi * 2,
            life: 1.1,
          ),
        );
        parent.add(ImpactFlash(at: at.clone(), maxRadius: 72));
      case ObjectKind.stalactite:
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [
              Color(0xFFB0BEC5),
              Color(0xFF78909C),
              Color(0xFFE0F7FA),
            ],
            count: 14,
            speed: 140,
          ),
        );
      case ObjectKind.pathSpike:
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
      default:
        parent.add(
          ParticleBurst(
            at: at.clone(),
            colors: const [Color(0xFF78909C), Color(0xFF455A64)],
            count: 10,
            speed: 110,
          ),
        );
    }
  }

  static void _rockBurst(Component parent, Vector2 at, ObjectKind kind) {
    final base = switch (kind) {
      ObjectKind.rockLarge => const Color(0xFF6D4C41),
      ObjectKind.rockMedium => const Color(0xFF8D6E63),
      _ => const Color(0xFFA1887F),
    };
    parent.add(
      ParticleBurst(
        at: at.clone(),
        colors: [base, const Color(0xFFBCAAA4), const Color(0xFF5D4037)],
        count: 14,
        speed: 150,
      ),
    );
    parent.add(
      ParticleBurst(
        at: at.clone(),
        colors: const [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
        count: 8,
        speed: 45,
        spread: math.pi,
        baseAngle: -math.pi / 2,
        life: 0.75,
      ),
    );
    final rng = math.Random();
    for (var i = 0; i < 3; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      parent.add(
        DebrisShard(
          at: at.clone(),
          velocity: Vector2(math.cos(ang) * 180, math.sin(ang) * 180 - 60),
          color: base,
          shardSize: kind == ObjectKind.rockLarge ? 18 : 12,
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
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [
              Color(0xFFFF5722),
              Color(0xFFFF9800),
              Color(0xFF424242),
            ],
            count: 12,
            speed: 95,
            spread: math.pi * 2,
            life: 0.42,
          ),
        );
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [Color(0xFFFFCC80), Color(0xFFFFE0B2)],
            count: 6,
            speed: 45,
            spread: math.pi * 2,
            life: 0.35,
          ),
        );
      case ObjectKind.spider:
      case ObjectKind.bossSpider:
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [
              Color(0xFF7CB342),
              Color(0xFF8D6E63),
              Color(0xFF33691E),
            ],
            count: 10,
            speed: 75,
            spread: math.pi * 1.1,
            life: 0.4,
          ),
        );
      case ObjectKind.pathSpike:
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [
              Color(0xFFFFB74D),
              Color(0xFF78909C),
              Color(0xFF5D4037),
            ],
            count: 9,
            speed: 80,
            spread: math.pi * 0.9,
            baseAngle: -math.pi / 2,
            life: 0.38,
          ),
        );
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
      case ObjectKind.debris:
        parent.add(
          ParticleBurst(
            at: impact,
            colors: const [
              Color(0xFF8D6E63),
              Color(0xFFBCAAA4),
              Color(0xFF6D4C41),
            ],
            count: kind == ObjectKind.rockLarge ? 12 : 9,
            speed: 80,
            spread: math.pi * 1.05,
            life: 0.4,
          ),
        );
        final rng = math.Random();
        for (var i = 0; i < 2; i++) {
          final ang = rng.nextDouble() * math.pi * 2;
          parent.add(
            DebrisShard(
              at: impact.clone(),
              velocity: Vector2(
                math.cos(ang) * 70,
                math.sin(ang) * 70 - 30,
              ),
              color: const Color(0xFF8D6E63),
              shardSize: 7,
            ),
          );
        }
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
      ObjectKind.diamond => const [
          Color(0xFF80DEEA),
          Color(0xFFB0BEC5),
          Color(0xFFD7CCC8),
        ],
      ObjectKind.goldNugget => const [
          Color(0xFFFFD54F),
          Color(0xFFBCAAA4),
          Color(0xFF8D6E63),
        ],
      ObjectKind.dynamite => const [
          Color(0xFFFF8A65),
          Color(0xFF8D6E63),
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
        kind == ObjectKind.debris) {
      final rng = math.Random();
      final base = kind == ObjectKind.rockLarge
          ? const Color(0xFF6D4C41)
          : const Color(0xFF8D6E63);
      for (var i = 0; i < 2; i++) {
        final ang = -math.pi / 2 + (rng.nextDouble() - 0.5) * 1.4;
        parent.add(
          DebrisShard(
            at: impact.clone(),
            velocity: Vector2(math.cos(ang) * 90, math.sin(ang) * 70 - 20),
            color: base,
            shardSize: kind == ObjectKind.rockLarge ? 12 : 8,
          ),
        );
      }
    }
  }
}
