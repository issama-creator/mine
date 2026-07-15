import 'package:flutter/material.dart';

enum GameEventKind {
  rockfall,
  crystalRain,
  spiderNest,
  treasureRush,
  dynamiteZone,
}

extension GameEventKindX on GameEventKind {
  String get title => switch (this) {
        GameEventKind.rockfall => 'ROCKFALL!',
        GameEventKind.crystalRain => 'CRYSTAL RAIN',
        GameEventKind.spiderNest => 'SPIDER NEST',
        GameEventKind.treasureRush => 'TREASURE RUSH',
        GameEventKind.dynamiteZone => 'DYNAMITE ZONE',
      };

  Color get accentColor => switch (this) {
        GameEventKind.rockfall => const Color(0xFF8D6E63),
        GameEventKind.crystalRain => const Color(0xFF80DEEA),
        GameEventKind.spiderNest => const Color(0xFF7CB342),
        GameEventKind.treasureRush => const Color(0xFFFFD54F),
        GameEventKind.dynamiteZone => const Color(0xFFFF5722),
      };
}
