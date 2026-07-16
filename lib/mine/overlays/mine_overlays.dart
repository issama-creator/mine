import 'package:flutter/material.dart';

import '../mine_runner_game.dart';
import '../models/game_event.dart';
import 'animated_juice_text.dart';
import 'mine_main_menu.dart';

class MineHudOverlay extends StatelessWidget {
  const MineHudOverlay({super.key, required this.game});
  final MineRunnerGame game;

  static const _hudShadow = <Shadow>[
    Shadow(blurRadius: 10, color: Color(0xCC000000), offset: Offset(0, 2)),
    Shadow(blurRadius: 2, color: Color(0x88000000)),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: game.meters,
                    builder: (_, m, __) => Text(
                      '$m m',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        shadows: _hudShadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      shadows: _hudShadow,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: game.scores.scoreNotifier,
                    builder: (_, s, __) => Text(
                      '$s',
                      style: TextStyle(
                        color: const Color(0xFFFFD54F),
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        height: 1.1,
                        shadows: _hudShadow,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: game.scores.highScoreNotifier,
                    builder: (_, h, __) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'BEST $h',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          shadows: _hudShadow,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 8,
            child: IconButton(
              onPressed: game.togglePause,
              icon: const Icon(Icons.pause, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class MineEventOverlay extends StatelessWidget {
  const MineEventOverlay({super.key, required this.game});
  final MineRunnerGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<GameEventKind?>(
        valueListenable: game.eventBanner,
        builder: (_, kind, __) {
          if (kind == null) return const SizedBox.shrink();
          return Align(
            alignment: const Alignment(0, -0.35),
            child: AnimatedJuiceText(
              text: kind.title,
              glowColor: kind.accentColor,
              style: TextStyle(
                color: kind.accentColor,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    blurRadius: 24,
                    color: kind.accentColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MineTitleOverlay extends StatelessWidget {
  const MineTitleOverlay({super.key, required this.game});
  final MineRunnerGame game;

  @override
  Widget build(BuildContext context) => MineMainMenu(game: game);
}

class MineGameOverOverlay extends StatelessWidget {
  const MineGameOverOverlay({super.key, required this.game});
  final MineRunnerGame game;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: game.restart,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A120C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6D4C41)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnimatedJuiceText(
                  text: 'GAME OVER',
                  glowColor: Color(0xFFFF5252),
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${game.meters.value} m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Score ${game.scores.score}',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                Text(
                  'Best Combo ${game.scores.bestCombo}',
                  style: const TextStyle(color: Colors.white54),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: game.scores.highScoreNotifier,
                  builder: (_, h, __) => Text(
                    'High Score $h',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: game.restart,
                      child: const Text('ЕЩЁ РАЗ'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: game.returnToMenu,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Color(0xFF6D4C41)),
                      ),
                      child: const Text('МЕНЮ'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'или тап по экрану',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
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

class MinePauseOverlay extends StatelessWidget {
  const MinePauseOverlay({super.key, required this.game});
  final MineRunnerGame game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: game.togglePause,
              child: const Text('ПРОДОЛЖИТЬ'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: game.returnToMenu,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white60,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Text('В МЕНЮ'),
            ),
          ],
        ),
      ),
    );
  }
}
