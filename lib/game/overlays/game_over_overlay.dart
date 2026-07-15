import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/hypno_colors.dart';
import '../hypno_roll_game.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final HypnoRollGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
          decoration: BoxDecoration(
            color: const Color(0xF0160E24),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HypnoColors.hazard.withValues(alpha: 0.6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SIGNAL LOST',
                style: TextStyle(
                  color: HypnoColors.hazard,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: game.deathReason,
                builder: (_, reason, __) => Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HypnoColors.ui,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<int>(
                valueListenable: game.meters,
                builder: (_, m, __) => Text(
                  '$m m',
                  style: const TextStyle(
                    color: HypnoColors.ui,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<int>(
                valueListenable: game.best,
                builder: (_, b, __) => ValueListenableBuilder<int>(
                  valueListenable: game.bestCombo,
                  builder: (_, bc, __) => Text(
                    'BEST  $b m   ·   COMBO $bc',
                    style: const TextStyle(
                      color: HypnoColors.uiDim,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  game.restart();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: HypnoColors.roadGlow),
                  ),
                  child: const Text(
                    'AGAIN',
                    style: TextStyle(
                      color: HypnoColors.ui,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
