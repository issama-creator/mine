import 'package:flutter/material.dart';

import '../theme/pulse_colors.dart';

/// Cosmetic pulse skins — no gameplay advantage.
class PulseSkin {
  const PulseSkin({
    required this.id,
    required this.name,
    required this.cost,
    required this.pulse,
    required this.pulseHot,
    required this.smash,
    required this.smashHot,
    required this.gate,
    required this.trail,
  });

  final String id;
  final String name;
  final int cost;
  final Color pulse;
  final Color pulseHot;
  final Color smash;
  final Color smashHot;
  final Color gate;
  final Color trail;
}

abstract final class PulseSkins {
  static const neon = PulseSkin(
    id: 'neon',
    name: 'NEON',
    cost: 0,
    pulse: PulseColors.pulse,
    pulseHot: PulseColors.pulseHot,
    smash: PulseColors.smash,
    smashHot: PulseColors.smashHot,
    gate: PulseColors.gate,
    trail: PulseColors.pulse,
  );

  static const solar = PulseSkin(
    id: 'solar',
    name: 'SOLAR',
    cost: 500,
    pulse: Color(0xFFFFD54F),
    pulseHot: Color(0xFFFFF8E1),
    smash: Color(0xFFFF5722),
    smashHot: Color(0xFFFFAB91),
    gate: Color(0xFFFFB300),
    trail: Color(0xFFFF9800),
  );

  static const frost = PulseSkin(
    id: 'frost',
    name: 'FROST',
    cost: 800,
    pulse: Color(0xFF64B5F6),
    pulseHot: Color(0xFFE3F2FD),
    smash: Color(0xFF5C6BC0),
    smashHot: Color(0xFF9FA8DA),
    gate: Color(0xFF80DEEA),
    trail: Color(0xFF42A5F5),
  );

  static const all = [neon, solar, frost];

  static PulseSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => neon);
}
