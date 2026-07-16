import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../managers/settings_manager.dart';
import '../mine_runner_game.dart';
import 'animated_juice_text.dart';

enum _MenuPage { main, records, settings }

/// Modest pre-game menu — start, records, settings.
class MineMainMenu extends StatefulWidget {
  const MineMainMenu({super.key, required this.game});

  final MineRunnerGame game;

  @override
  State<MineMainMenu> createState() => _MineMainMenuState();
}

class _MineMainMenuState extends State<MineMainMenu> {
  _MenuPage _page = _MenuPage.main;

  static const _gold = Color(0xFFFFD54F);
  static const _card = Color(0xE614100C);
  static const _border = Color(0xFF5D4037);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft vignette — game world visible behind.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.72),
                  const Color(0xFF0D0A08).withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (_page) {
        _MenuPage.main => _mainPage(key: const ValueKey('main')),
        _MenuPage.records => _recordsPage(key: const ValueKey('records')),
        _MenuPage.settings => _settingsPage(key: const ValueKey('settings')),
      },
    );
  }

  Widget _shell({required Widget child, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _mainPage({Key? key}) {
    return _shell(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnimatedJuiceText(
            text: 'MINE RUSH',
            glowColor: _gold,
            style: TextStyle(
              color: _gold,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Шахта сыпется — режь и выживай',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          _MenuButton.primary(
            label: 'НАЧАТЬ ИГРУ',
            onTap: () {
              HapticFeedback.lightImpact();
              widget.game.startRun();
            },
          ),
          const SizedBox(height: 10),
          _MenuButton.secondary(
            label: 'МОИ РЕКОРДЫ',
            onTap: () => setState(() => _page = _MenuPage.records),
          ),
          const SizedBox(height: 10),
          _MenuButton.secondary(
            label: 'НАСТРОЙКИ',
            onTap: () => setState(() => _page = _MenuPage.settings),
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<int>(
            valueListenable: widget.game.scores.highScoreNotifier,
            builder: (_, best, __) {
              if (best <= 0) return const SizedBox.shrink();
              return Text(
                'Рекорд: $best',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recordsPage({Key? key}) {
    final scores = widget.game.scores;
    return _shell(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header('МОИ РЕКОРДЫ'),
          const SizedBox(height: 18),
          ValueListenableBuilder<int>(
            valueListenable: scores.highScoreNotifier,
            builder: (_, v, __) => _RecordRow(
              icon: Icons.emoji_events_outlined,
              label: 'Лучший счёт',
              value: '$v',
              accent: _gold,
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: scores.bestMetersNotifier,
            builder: (_, v, __) => _RecordRow(
              icon: Icons.landscape_outlined,
              label: 'Дальность',
              value: '$v м',
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: scores.bestComboEverNotifier,
            builder: (_, v, __) => _RecordRow(
              icon: Icons.bolt_outlined,
              label: 'Лучшее комбо',
              value: 'x$v',
            ),
          ),
          const SizedBox(height: 22),
          _MenuButton.secondary(
            label: 'НАЗАД',
            onTap: () => setState(() => _page = _MenuPage.main),
          ),
        ],
      ),
    );
  }

  Widget _settingsPage({Key? key}) {
    final settings = SettingsManager.instance;
    return _shell(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header('НАСТРОЙКИ'),
          const SizedBox(height: 14),
          ValueListenableBuilder<bool>(
            valueListenable: settings.soundNotifier,
            builder: (_, on, __) => _SettingToggle(
              label: 'Звук',
              value: on,
              onChanged: settings.setSound,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: settings.vibrationNotifier,
            builder: (_, on, __) => _SettingToggle(
              label: 'Вибрация',
              value: on,
              onChanged: settings.setVibration,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Как играть',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _hint('Тап — разрушить камень или опасность'),
          _hint('Кристалл — 5 сек режима среза'),
          _hint('Каждые 600 м — новая шахта'),
          const SizedBox(height: 18),
          _MenuButton.secondary(
            label: 'НАЗАД',
            onTap: () => setState(() => _page = _MenuPage.main),
          ),
        ],
      ),
    );
  }

  Widget _header(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '· $text',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton._({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  factory _MenuButton.primary({required String label, required VoidCallback onTap}) {
    return _MenuButton._(label: label, onTap: onTap, primary: true);
  }

  factory _MenuButton.secondary({required String label, required VoidCallback onTap}) {
    return _MenuButton._(label: label, onTap: onTap, primary: false);
  }

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: primary ? const Color(0xFF6D4C41) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary
                    ? const Color(0xFF8D6E63)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w800,
                letterSpacing: primary ? 2.5 : 1.8,
                fontSize: primary ? 15 : 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent ?? Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent ?? Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF8D6E63),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
