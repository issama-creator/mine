import 'package:flutter/material.dart';

import '../pulse_lane_game.dart';

/// Full-screen swipe + hold catcher (doesn't rebuild with HUD).
class PulseInputOverlay extends StatefulWidget {
  const PulseInputOverlay({super.key, required this.game});
  final PulseLaneGame game;

  @override
  State<PulseInputOverlay> createState() => _PulseInputOverlayState();
}

class _PulseInputOverlayState extends State<PulseInputOverlay> {
  PulseLaneGame get game => widget.game;

  int? _pointer;
  Offset? _origin;
  DateTime? _lastLaneAt;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        if (!game.started.value || game.isGameOver) {
          game.startRun();
          return;
        }
        _pointer = e.pointer;
        _origin = e.localPosition;
        game.touchDown();
      },
      onPointerMove: (e) {
        if (_pointer != e.pointer || _origin == null) return;
        final d = e.localPosition - _origin!;
        // Softer swipe: slightly more travel + cooldown so it doesn't stutter
        final now = DateTime.now();
        final cooled = _lastLaneAt == null ||
            now.difference(_lastLaneAt!) > const Duration(milliseconds: 180);
        if (cooled &&
            d.dx.abs() > 50 &&
            d.dx.abs() > d.dy.abs() * 1.28) {
          game.nudgeLane(d.dx > 0 ? 1 : -1);
          _origin = e.localPosition;
          _lastLaneAt = now;
          return;
        }
        if (d.dy > 32) {
          game.setCollapse(true);
        }
      },
      onPointerUp: (e) {
        if (_pointer != null && _pointer != e.pointer) return;
        game.touchUp();
        _pointer = null;
        _origin = null;
      },
      onPointerCancel: (_) {
        game.touchUp();
        _pointer = null;
        _origin = null;
      },
      child: const SizedBox.expand(),
    );
  }
}
