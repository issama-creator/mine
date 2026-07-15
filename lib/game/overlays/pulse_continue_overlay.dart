import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/pulse_colors.dart';
import '../pulse_lane_game.dart';

class PulseContinueOverlay extends StatelessWidget {
  const PulseContinueOverlay({super.key, required this.game});
  final PulseLaneGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xF00E1620),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PulseColors.pulse.withValues(alpha: 0.7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SECOND CHANCE',
                style: TextStyle(
                  color: PulseColors.pulse,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1 раз за забег',
                style: TextStyle(color: PulseColors.uiDim, fontSize: 13),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  game.useSecondChance();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: PulseColors.pulse, width: 2),
                    color: PulseColors.pulse.withValues(alpha: 0.15),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: PulseColors.ui,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  game.declineSecondChance();
                },
                child: const Text(
                  'Нет, AGAIN',
                  style: TextStyle(
                    color: PulseColors.uiDim,
                    fontWeight: FontWeight.w700,
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
