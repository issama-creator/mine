import 'package:flutter/material.dart';

import '../hypno_roll_game.dart';

/// Full-screen hold-to-draw catcher. Kept as its own Flame overlay (under HUD)
/// so UI rebuilds never remount this and kill the pointer hold.
class DrawOverlay extends StatefulWidget {
  const DrawOverlay({super.key, required this.game});
  final HypnoRollGame game;

  @override
  State<DrawOverlay> createState() => _DrawOverlayState();
}

class _DrawOverlayState extends State<DrawOverlay> {
  HypnoRollGame get game => widget.game;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        game.pointerDown(e.pointer, e.localPosition);
      },
      onPointerMove: (e) {
        game.pointerMove(e.pointer, e.localPosition);
      },
      onPointerUp: (e) {
        game.pointerUp(e.pointer);
      },
      // Web often fires cancel mid-hold — ignore so pour keeps going.
      onPointerCancel: (_) {},
      child: const SizedBox.expand(),
    );
  }
}
