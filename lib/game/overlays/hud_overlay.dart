import 'package:flutter/material.dart';

import '../../theme/hypno_colors.dart';
import '../hypno_roll_game.dart';

/// Drawing surface kept ALIVE with a stable State so holds aren't cancelled.
class HudOverlay extends StatefulWidget {
  const HudOverlay({super.key, required this.game});
  final HypnoRollGame game;

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  HypnoRollGame get game => widget.game;

  @override
  Widget build(BuildContext context) {
    // No full-screen catcher here — DrawOverlay underneath gets the holds.
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) UI that must NOT steal draw gestures
        IgnorePointer(
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: game.meters,
                        builder: (_, m, __) => Text(
                          '$m m',
                          style: const TextStyle(
                            color: HypnoColors.ui,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black)
                            ],
                          ),
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: game.combo,
                        builder: (_, c, __) {
                          if (c < 1) return const SizedBox(height: 4);
                          return Text(
                            'COMBO $c',
                            style: const TextStyle(
                              color: HypnoColors.ring,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: game.mirrorActive,
                        builder: (_, on, __) {
                          if (!on) return const SizedBox.shrink();
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'MIRROR — рисуй наоборот',
                              style: TextStyle(
                                color: HypnoColors.fake,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            // PATH — how far in the current segment / how much left
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                game.pathProgress,
                                game.pathPassed,
                                game.pathLeft,
                                game.meters,
                              ]),
                              builder: (_, __) {
                                final pass = game.pathPassed.value;
                                final left = game.pathLeft.value;
                                final seg = game.meters.value ~/
                                        HypnoRollGame.segmentLen +
                                    1;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'PATH',
                                          style: TextStyle(
                                            color: HypnoColors.uiDim,
                                            fontSize: 10,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '$pass m · left $left · seg $seg',
                                          style: const TextStyle(
                                            color: HypnoColors.uiDim,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: game.pathProgress.value,
                                        minHeight: 7,
                                        backgroundColor: Colors.white12,
                                        color: HypnoColors.roadGlow,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 18,
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.bestCombo,
                    builder: (_, bc, __) => Text(
                      'Рисуй у шара — веди путь вперёд  ·  COMBO $bc',
                      style: const TextStyle(
                        color: HypnoColors.uiDim,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Buttons above draw overlay (draw is a separate Flame overlay under this)
        SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: game.canSave,
                    builder: (_, ready, __) => Opacity(
                      opacity: ready ? 1 : 0.35,
                      child: _RoundBtn(
                        label: 'SAVE',
                        color: HypnoColors.pad,
                        pulse: ready,
                        badge: ValueListenableBuilder<int>(
                          valueListenable: game.pads,
                          builder: (_, n, __) => Text(
                            '$n',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        onTap: game.usePad,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<bool>(
                    valueListenable: game.trustMode,
                    builder: (_, trust, __) => _RoundBtn(
                      label: trust ? 'TRUST' : 'PANIC',
                      color: trust ? HypnoColors.trust : HypnoColors.panic,
                      onTap: game.toggleMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.pulse = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? badge;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: pulse ? 3.5 : 2.5),
          color: color.withValues(alpha: pulse ? 0.32 : 0.18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: pulse ? 0.55 : 0.3),
              blurRadius: pulse ? 18 : 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            if (badge != null) ...[const SizedBox(height: 2), badge!],
          ],
        ),
      ),
    );
  }
}
