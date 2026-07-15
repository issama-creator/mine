import 'package:flutter/services.dart';

/// Tiny SFX without assets — haptics + system clicks.
abstract final class Sfx {
  static void draw() => SystemSound.play(SystemSoundType.click);

  static void nearMiss() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  static void perfect() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void speedUp() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void pad() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void die() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  static void toggle() => HapticFeedback.selectionClick();
}
