import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/hypno_colors.dart';
import '../road_path.dart';

class RoadRenderer extends Component with HasGameReference {
  RoadRenderer({required this.road, required this.cameraX});

  final RoadPath road;
  double Function() cameraX;
  double time = 0;
  bool showFake = true;
  /// Live finger position while drawing (screen space).
  Offset? fingerScreen;

  @override
  int get priority => 2;

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!road.hasPoints) return;
    final cam = cameraX();

    if (showFake) {
      canvas.drawPath(
        road.fakeScreenPath(cam, time),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = HypnoColors.fake.withValues(alpha: 0.28),
      );
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = HypnoColors.roadGlow.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = HypnoColors.road;

    final path = road.toScreenPath(cam);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, roadPaint);

    // Live draw feedback — ghost line to finger
    final finger = fingerScreen;
    if (finger != null && road.hasPoints) {
      final tip = road.points.last;
      final tipScreen = Offset(tip.dx - cam, tip.dy);
      final ghost = Path()
        ..moveTo(tipScreen.dx, tipScreen.dy)
        ..lineTo(finger.dx, finger.dy);
      canvas.drawPath(
        ghost,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = HypnoColors.roadGlow.withValues(alpha: 0.45),
      );
      canvas.drawCircle(
        finger,
        9,
        Paint()
          ..color = HypnoColors.roadGlow.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        finger,
        5,
        Paint()..color = HypnoColors.road,
      );
    }
  }
}
