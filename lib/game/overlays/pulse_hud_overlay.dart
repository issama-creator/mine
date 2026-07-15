import 'package:flutter/material.dart';



import '../../theme/pulse_colors.dart';

import '../pulse_lane_game.dart';

import '../pulse_progress.dart';



class PulseHudOverlay extends StatelessWidget {

  const PulseHudOverlay({super.key, required this.game});

  final PulseLaneGame game;



  @override

  Widget build(BuildContext context) {

    final progress = PulseProgress.instance;

    return IgnorePointer(

      child: SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),

          child: Column(

            children: [

              Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  ValueListenableBuilder<int>(

                    valueListenable: game.toStation,

                    builder: (_, d, __) => Text(

                      'СТАНЦИЯ $d m',

                      style: const TextStyle(

                        color: PulseColors.gate,

                        fontSize: 12,

                        fontWeight: FontWeight.w800,

                        letterSpacing: 1,

                      ),

                    ),

                  ),

                  ValueListenableBuilder<int>(

                    valueListenable: progress.coins,

                    builder: (_, c, __) => Text(

                      '🪙 $c',

                      style: const TextStyle(

                        color: PulseColors.coinGlow,

                        fontSize: 13,

                        fontWeight: FontWeight.w800,

                      ),

                    ),

                  ),

                ],

              ),

              ValueListenableBuilder<String>(
                valueListenable: game.stationToast,
                builder: (_, toast, __) {
                  if (toast.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      toast,
                      style: const TextStyle(
                        color: PulseColors.pulse,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),

              ValueListenableBuilder<String>(
                valueListenable: game.hauntLabel,
                builder: (_, label, __) {
                  if (label.isEmpty) return const SizedBox(height: 2);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE1BEE7),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),

              ValueListenableBuilder<int>(

                valueListenable: game.meters,

                builder: (_, m, __) => Text(

                  '$m m',

                  style: const TextStyle(

                    color: PulseColors.ui,

                    fontSize: 40,

                    fontWeight: FontWeight.w900,

                    shadows: [Shadow(blurRadius: 12, color: Colors.black)],

                  ),

                ),

              ),

              ValueListenableBuilder<int>(

                valueListenable: game.runCoins,

                builder: (_, rc, __) => ValueListenableBuilder<int>(

                  valueListenable: game.score,

                  builder: (_, s, __) => Text(

                    '+$rc coins · $s pts',

                    style: const TextStyle(

                      color: PulseColors.uiDim,

                      fontSize: 13,

                      fontWeight: FontWeight.w700,

                      letterSpacing: 1,

                    ),

                  ),

                ),

              ),

              const SizedBox(height: 6),

              Row(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  ValueListenableBuilder<int>(

                    valueListenable: game.formStreak,

                    builder: (_, fs, __) {

                      if (fs < 1) return const SizedBox.shrink();

                      return Container(

                        margin: const EdgeInsets.only(right: 8),

                        padding: const EdgeInsets.symmetric(

                          horizontal: 10,

                          vertical: 4,

                        ),

                        decoration: BoxDecoration(

                          borderRadius: BorderRadius.circular(14),

                          color: PulseColors.pulse.withValues(alpha: 0.2),

                          border: Border.all(color: PulseColors.pulse),

                        ),

                        child: Text(

                          'FORM $fs',

                          style: const TextStyle(

                            color: PulseColors.pulseHot,

                            fontWeight: FontWeight.w900,

                            fontSize: 12,

                          ),

                        ),

                      );

                    },

                  ),

                  ValueListenableBuilder<double>(

                    valueListenable: game.coinMultiplier,

                    builder: (_, mult, __) {

                      if (mult <= 1.01) return const SizedBox.shrink();

                      return Container(

                        margin: const EdgeInsets.only(right: 8),

                        padding: const EdgeInsets.symmetric(

                          horizontal: 8,

                          vertical: 4,

                        ),

                        decoration: BoxDecoration(

                          borderRadius: BorderRadius.circular(12),

                          color: PulseColors.coin.withValues(alpha: 0.12),

                          border: Border.all(color: PulseColors.coin),

                        ),

                        child: Text(

                          '×${mult.toStringAsFixed(1)}',

                          style: const TextStyle(

                            color: PulseColors.coinGlow,

                            fontWeight: FontWeight.w900,

                            fontSize: 11,

                          ),

                        ),

                      );

                    },

                  ),

                  ValueListenableBuilder<String>(

                    valueListenable: game.formLabel,

                    builder: (_, form, __) {

                      final smash = form == 'SMASH';

                      final color =

                          smash ? PulseColors.smash : PulseColors.gate;

                      return Container(

                        padding: const EdgeInsets.symmetric(

                          horizontal: 12,

                          vertical: 5,

                        ),

                        decoration: BoxDecoration(

                          borderRadius: BorderRadius.circular(16),

                          border: Border.all(color: color, width: 1.5),

                          color: color.withValues(alpha: 0.18),

                        ),

                        child: Text(

                          smash ? 'SMASH' : 'SLIM',

                          style: TextStyle(

                            color: color,

                            fontWeight: FontWeight.w900,

                            letterSpacing: 1.5,

                            fontSize: 12,

                          ),

                        ),

                      );

                    },

                  ),

                ],

              ),

              ValueListenableBuilder<double>(

                valueListenable: game.holdRemain,

                builder: (_, h, __) {

                  if (h <= 0.01) return const SizedBox(height: 4);

                  return Padding(

                    padding: const EdgeInsets.only(top: 4),

                    child: Text(

                      'держи ещё ${(h * 10).ceil() / 10}s',

                      style: const TextStyle(

                        color: PulseColors.gate,

                        fontSize: 11,

                        fontWeight: FontWeight.w700,

                      ),

                    ),

                  );

                },

              ),

              ValueListenableBuilder<bool>(

                valueListenable: game.feverActive,

                builder: (_, on, __) {

                  if (!on) return const SizedBox(height: 4);

                  return ValueListenableBuilder<int>(

                    valueListenable: game.feverHits,

                    builder: (_, hits, __) => Padding(

                      padding: const EdgeInsets.only(top: 6),

                      child: Text(

                        'PULSE FEVER · $hits HITS',

                        style: const TextStyle(

                          color: PulseColors.gate,

                          fontWeight: FontWeight.w900,

                          letterSpacing: 2,

                          fontSize: 13,

                        ),

                      ),

                    ),

                  );

                },

              ),

              ValueListenableBuilder<int>(

                valueListenable: game.closeCount,

                builder: (_, close, __) {

                  if (close < 1) return const SizedBox(height: 4);

                  return Padding(

                    padding: const EdgeInsets.only(top: 4),

                    child: Text(

                      'CLOSE $close',

                      style: const TextStyle(

                        color: PulseColors.pulseHot,

                        fontWeight: FontWeight.w800,

                        fontSize: 12,

                      ),

                    ),

                  );

                },

              ),

              ValueListenableBuilder<String>(

                valueListenable: game.tip,

                builder: (_, t, __) {

                  if (t.isEmpty) return const SizedBox.shrink();

                  return Padding(

                    padding: const EdgeInsets.only(top: 6),

                    child: Text(

                      t,

                      textAlign: TextAlign.center,

                      style: TextStyle(

                        color: PulseColors.ui.withValues(alpha: 0.85),

                        fontSize: 12,

                        fontWeight: FontWeight.w600,

                        shadows: const [Shadow(blurRadius: 8, color: Colors.black)],

                      ),

                    ),

                  );

                },

              ),

              const Spacer(),

              const Padding(

                padding: EdgeInsets.only(bottom: 16),

                child: Text(

                  'СВАЙП полоса · УДЕРЖИ slim · ОТПУСТИ smash',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: PulseColors.uiDim,

                    fontSize: 11,

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

