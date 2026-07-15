import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



import '../../theme/pulse_colors.dart';

import '../pulse_lane_game.dart';

import '../pulse_progress.dart';

import '../pulse_skins.dart';



class PulseTitleOverlay extends StatefulWidget {

  const PulseTitleOverlay({super.key, required this.game});

  final PulseLaneGame game;



  @override

  State<PulseTitleOverlay> createState() => _PulseTitleOverlayState();

}



class _PulseTitleOverlayState extends State<PulseTitleOverlay> {
  bool _showSkins = false;
  bool _showHaunts = false;



  @override

  Widget build(BuildContext context) {

    final progress = PulseProgress.instance;

    return Material(

      color: Colors.black54,

      child: SafeArea(

        child: Center(

          child: SingleChildScrollView(

            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                const Text(

                  'PULSE',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: PulseColors.pulse,

                    fontSize: 42,

                    fontWeight: FontWeight.w900,

                    letterSpacing: 6,

                    shadows: [Shadow(blurRadius: 18, color: Colors.black)],

                  ),

                ),

                const Text(

                  'ФОРМА = ЖИЗНЬ',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: PulseColors.smash,

                    fontSize: 16,

                    fontWeight: FontWeight.w800,

                    letterSpacing: 3,

                  ),

                ),

                const SizedBox(height: 10),

                const Text(

                  'Slim, smash, survive — до станции 60 m',

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: PulseColors.uiDim,

                    fontSize: 13,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 14),

                ValueListenableBuilder<String>(

                  valueListenable: widget.game.dailyLabel,

                  builder: (_, label, __) => ValueListenableBuilder<bool>(

                    valueListenable: progress.dailyDone,

                    builder: (_, done, __) => Container(

                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(

                          color: done

                              ? PulseColors.pulse

                              : PulseColors.gate.withValues(alpha: 0.6),

                        ),

                        color: PulseColors.voidMid.withValues(alpha: 0.6),

                      ),

                      child: Column(

                        children: [

                          Text(

                            done ? 'DAILY ✓' : 'DAILY',

                            style: TextStyle(

                              color: done

                                  ? PulseColors.pulse

                                  : PulseColors.gate,

                              fontWeight: FontWeight.w900,

                              letterSpacing: 2,

                              fontSize: 12,

                            ),

                          ),

                          const SizedBox(height: 4),

                          Text(

                            label,

                            textAlign: TextAlign.center,

                            style: const TextStyle(

                              color: PulseColors.ui,

                              fontSize: 13,

                              fontWeight: FontWeight.w600,

                            ),

                          ),

                          const SizedBox(height: 4),

                          Text(

                            'Seed #${progress.dailySeed}',

                            style: const TextStyle(

                              color: PulseColors.uiDim,

                              fontSize: 11,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 12),

                ValueListenableBuilder<int>(

                  valueListenable: progress.coins,

                  builder: (_, coins, __) => Text(

                    '🪙 $coins Pulse Coins',

                    style: const TextStyle(

                      color: PulseColors.coinGlow,

                      fontWeight: FontWeight.w800,

                      fontSize: 14,

                    ),

                  ),

                ),

                ValueListenableBuilder(
                  valueListenable: progress.pendingHaunt,
                  builder: (_, haunt, __) {
                    if (haunt == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFB388FF).withValues(alpha: 0.7),
                          ),
                          color: const Color(0xFF1A1030).withValues(alpha: 0.7),
                        ),
                        child: Text(
                          '👻 Ждёт на ~25 m: ${haunt.name}'
                          '${haunt.power > 1 ? ' · x${haunt.power}' : ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFE1BEE7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                ValueListenableBuilder<int>(

                  valueListenable: progress.bestMeters,

                  builder: (_, bm, __) => ValueListenableBuilder<int>(

                    valueListenable: progress.bestForm,

                    builder: (_, bf, __) => ValueListenableBuilder<int>(

                      valueListenable: progress.bestClose,

                      builder: (_, bc, __) => Text(

                        'BEST  $bm m  ·  FORM $bf  ·  CLOSE $bc',

                        style: const TextStyle(

                          color: PulseColors.uiDim,

                          letterSpacing: 1,

                          fontWeight: FontWeight.w700,

                          fontSize: 12,

                        ),

                      ),

                    ),

                  ),

                ),

                if (_showSkins) ...[

                  const SizedBox(height: 16),

                  const Text(

                    'СКИНЫ',

                    style: TextStyle(

                      color: PulseColors.ui,

                      fontWeight: FontWeight.w900,

                      letterSpacing: 2,

                    ),

                  ),

                  const SizedBox(height: 8),

                  ...PulseSkins.all.map((skin) {

                    final unlocked = widget.game.isSkinUnlocked(skin.id);

                    return Padding(

                      padding: const EdgeInsets.only(bottom: 8),

                      child: GestureDetector(

                        onTap: () async {

                          HapticFeedback.selectionClick();

                          if (unlocked) {

                            await widget.game.selectSkin(skin.id);

                          } else if (progress.coins.value >= skin.cost) {

                            await widget.game.buySkin(skin.id, skin.cost);

                          }

                          setState(() {});

                        },

                        child: Container(

                          padding: const EdgeInsets.symmetric(

                            horizontal: 16,

                            vertical: 10,

                          ),

                          decoration: BoxDecoration(

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(color: skin.pulse),

                            color: skin.pulse.withValues(alpha: 0.1),

                          ),

                          child: Row(

                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [

                              Text(

                                skin.name,

                                style: TextStyle(

                                  color: skin.pulseHot,

                                  fontWeight: FontWeight.w800,

                                ),

                              ),

                              Text(

                                unlocked

                                    ? (progress.selectedSkinId.value == skin.id

                                        ? 'ON'

                                        : 'OWNED')

                                    : '${skin.cost} 🪙',

                                style: const TextStyle(

                                  color: PulseColors.uiDim,

                                  fontWeight: FontWeight.w700,

                                  fontSize: 12,

                                ),

                              ),

                            ],

                          ),

                        ),

                      ),

                    );

                  }),

                ],

                if (_showHaunts) ...[
                  const SizedBox(height: 14),
                  ValueListenableBuilder<int>(
                    valueListenable: progress.capturedHauntCount,
                    builder: (_, count, __) => Text(
                      'ПРИЗРАКИ · $count поймано',
                      style: const TextStyle(
                        color: Color(0xFFE1BEE7),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...progress.capturedHaunts.take(8).map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '✓ ${h.name}',
                        style: const TextStyle(
                          color: PulseColors.uiDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                GestureDetector(

                  onTap: () {

                    HapticFeedback.mediumImpact();

                    widget.game.startRun();

                  },

                  child: Container(

                    padding: const EdgeInsets.symmetric(

                      horizontal: 36,

                      vertical: 14,

                    ),

                    decoration: BoxDecoration(

                      borderRadius: BorderRadius.circular(32),

                      border: Border.all(color: PulseColors.pulse, width: 2),

                      color: PulseColors.pulse.withValues(alpha: 0.15),

                      boxShadow: [

                        BoxShadow(

                          color: PulseColors.pulse.withValues(alpha: 0.35),

                          blurRadius: 18,

                        ),

                      ],

                    ),

                    child: const Text(

                      'RUN',

                      style: TextStyle(

                        color: PulseColors.ui,

                        fontWeight: FontWeight.w900,

                        letterSpacing: 3,

                        fontSize: 18,

                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 10),

                GestureDetector(

                  onTap: () => setState(() => _showHaunts = !_showHaunts),

                  child: Text(

                    _showHaunts ? 'Скрыть призраков' : 'Коллекция призраков',

                    style: const TextStyle(

                      color: Color(0xFFB388FF),

                      fontWeight: FontWeight.w700,

                      fontSize: 13,

                    ),

                  ),

                ),

                const SizedBox(height: 8),

                GestureDetector(

                  onTap: () => setState(() => _showSkins = !_showSkins),

                  child: Text(

                    _showSkins ? 'Скрыть скины' : 'Скины пульса',

                    style: const TextStyle(

                      color: PulseColors.uiDim,

                      fontWeight: FontWeight.w700,

                      fontSize: 13,

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

