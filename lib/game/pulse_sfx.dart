import 'package:flutter/services.dart';

/// Form + rhythm feedback without audio assets.
abstract final class PulseSfx {
  static void slimTick() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  static void smashHit() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void beatPulse() {
    SystemSound.play(SystemSoundType.click);
  }

  static void falseNote() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  static void coin() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void station() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void boost() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void fever() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void close() => HapticFeedback.selectionClick();

  static void hauntLaugh() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  static void hauntCaptured() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void die() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
}
