import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



import '../../theme/pulse_colors.dart';

import '../pulse_lane_game.dart';

import '../pulse_progress.dart';



class PulseGameOverOverlay extends StatelessWidget {

  const PulseGameOverOverlay({super.key, required this.game});

  final PulseLaneGame game;



  @override

  Widget build(BuildContext context) {

    final progress = PulseProgress.instance;

    final fromRecord = game.metersFromRecord;

    return Material(

      color: Colors.black54,

      child: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

          child: Container(

            padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),

            decoration: BoxDecoration(

              color: const Color(0xF00E1620),

              borderRadius: BorderRadius.circular(18),

              border: Border.all(

                color: PulseColors.hazard.withValues(alpha: 0.65),

              ),

            ),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                const Text(

                  'WRONG FORM',

                  style: TextStyle(

                    color: PulseColors.hazard,

                    fontSize: 24,

                    fontWeight: FontWeight.w900,

                    letterSpacing: 2,

                  ),

                ),

                const SizedBox(height: 8),

                ValueListenableBuilder<String>(

                  valueListenable: game.failReason,

                  builder: (_, reason, __) => Text(

                    reason.isEmpty ? 'Не та форма' : reason,

                    textAlign: TextAlign.center,

                    style: const TextStyle(

                      color: PulseColors.ui,

                      fontSize: 15,

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

                      color: PulseColors.ui,

                      fontSize: 44,

                      fontWeight: FontWeight.w800,

                    ),

                  ),

                ),

                if (fromRecord > 0 && fromRecord < 9999)

                  Padding(

                    padding: const EdgeInsets.only(top: 4),

                    child: Text(

                      'ты на $fromRecord m от рекорда',

                      style: const TextStyle(

                        color: PulseColors.gate,

                        fontWeight: FontWeight.w700,

                        fontSize: 13,

                      ),

                    ),

                  ),

                const SizedBox(height: 8),

                ValueListenableBuilder<int>(

                  valueListenable: game.closeCount,

                  builder: (_, close, __) => ValueListenableBuilder<int>(

                    valueListenable: progress.bestClose,

                    builder: (_, bestClose, __) {

                      final beatClose = close > bestClose;

                      return Column(

                        children: [

                          Text(

                            'CLOSE! $close',

                            style: const TextStyle(

                              color: PulseColors.pulseHot,

                              fontWeight: FontWeight.w900,

                              fontSize: 16,

                              letterSpacing: 1,

                            ),

                          ),

                          Text(

                            beatClose

                                ? 'новый рекорд CLOSE!'

                                : 'рекорд CLOSE: $bestClose',

                            style: TextStyle(

                              color: beatClose

                                  ? PulseColors.pulse

                                  : PulseColors.uiDim,

                              fontWeight: FontWeight.w700,

                              fontSize: 12,

                            ),

                          ),

                        ],

                      );

                    },

                  ),

                ),

                const SizedBox(height: 8),

                ValueListenableBuilder<int>(

                  valueListenable: game.runCoins,

                  builder: (_, rc, __) => Text(

                    '+$rc Pulse Coins',

                    style: const TextStyle(

                      color: PulseColors.coinGlow,

                      fontWeight: FontWeight.w800,

                    ),

                  ),

                ),

                const SizedBox(height: 6),

                ValueListenableBuilder<int>(

                  valueListenable: progress.bestMeters,

                  builder: (_, bm, __) => ValueListenableBuilder<int>(

                    valueListenable: progress.bestForm,

                    builder: (_, bf, __) => Text(

                      'BEST  $bm m   ·   FORM $bf',

                      style: const TextStyle(

                        color: PulseColors.uiDim,

                        letterSpacing: 1,

                        fontWeight: FontWeight.w700,

                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 12),

                Container(

                  padding:

                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                  decoration: BoxDecoration(

                    borderRadius: BorderRadius.circular(10),

                    color: PulseColors.voidMid,

                    border: Border.all(color: PulseColors.pulse.withValues(alpha: 0.4)),

                  ),

                  child: Text(

                    game.shareCardLine,

                    style: const TextStyle(

                      color: PulseColors.ui,

                      fontWeight: FontWeight.w800,

                      letterSpacing: 1,

                    ),

                  ),

                ),

                const SizedBox(height: 10),

                GestureDetector(

                  onTap: () {

                    Clipboard.setData(ClipboardData(text: game.shareCardLine));

                    HapticFeedback.lightImpact();

                  },

                  child: const Text(

                    'Копировать share card',

                    style: TextStyle(

                      color: PulseColors.uiDim,

                      fontWeight: FontWeight.w700,

                      fontSize: 12,

                    ),

                  ),

                ),

                const SizedBox(height: 20),

                GestureDetector(

                  onTap: () {

                    HapticFeedback.mediumImpact();

                    game.restart();

                  },

                  child: Container(

                    padding: const EdgeInsets.symmetric(

                      horizontal: 28,

                      vertical: 12,

                    ),

                    decoration: BoxDecoration(

                      borderRadius: BorderRadius.circular(28),

                      border: Border.all(color: PulseColors.pulse),

                    ),

                    child: const Text(

                      'AGAIN',

                      style: TextStyle(

                        color: PulseColors.ui,

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

      ),

    );

  }

}

