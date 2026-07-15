import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/hypno_colors.dart';
import '../hypno_roll_game.dart';

class TitleOverlay extends StatelessWidget {
  const TitleOverlay({super.key, required this.game});
  final HypnoRollGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              'HYPNO',
              style: TextStyle(
                color: HypnoColors.hypnoB,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 10,
                shadows: [
                  Shadow(
                    color: HypnoColors.hypnoA.withValues(alpha: 0.85),
                    blurRadius: 22,
                  ),
                ],
              ),
            ),
            const Text(
              'ROLL',
              style: TextStyle(
                color: HypnoColors.ui,
                fontSize: 40,
                fontWeight: FontWeight.w300,
                letterSpacing: 16,
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Шар летит вперёд.\nЗажми и веди пальцем — путь чертится live.\nДыра? Нарисуй мост. Падаешь? SAVE.\nTrust / Panic — твой выбор.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HypnoColors.uiDim,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                game.start();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: HypnoColors.roadGlow),
                  boxShadow: [
                    BoxShadow(
                      color: HypnoColors.roadGlow.withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Text(
                  'FLY',
                  style: TextStyle(
                    color: HypnoColors.ui,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
