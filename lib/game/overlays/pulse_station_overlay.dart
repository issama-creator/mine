import 'package:flutter/material.dart';

import '../../theme/pulse_colors.dart';
import '../pulse_lane_game.dart';

class PulseStationOverlay extends StatelessWidget {
  const PulseStationOverlay({super.key, required this.game});
  final PulseLaneGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.black38,
        child: Center(
          child: ValueListenableBuilder<int>(
            valueListenable: game.stationsThisRun,
            builder: (_, n, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'STATION REACHED',
                  style: TextStyle(
                    color: PulseColors.pulse,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '+${game.lastStationBonus} Pulse Coins',
                  style: const TextStyle(
                    color: PulseColors.coinGlow,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Станция #$n',
                  style: const TextStyle(
                    color: PulseColors.uiDim,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
