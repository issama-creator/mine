import 'dart:math' as math;
import 'dart:ui';

import 'pulse_config.dart';

/// Maps tunnel depth + lane → screen coordinates (perspective).
class TunnelSpace {
  TunnelSpace(this.size);

  Size size;

  Offset get vanishing => Offset(size.width * 0.5, size.height * 0.12);

  double laneX(int lane, double depth) {
    final t = _perspective(depth);
    final left = size.width * (0.5 - 0.42 * t);
    final right = size.width * (0.5 + 0.42 * t);
    final spacing = (right - left) / (PulseConfig.laneCount - 1);
    return left + spacing * lane;
  }

  double depthY(double depth) {
    final t = _perspective(depth);
    return vanishing.dy + (size.height * 0.86 - vanishing.dy) * t;
  }

  double scaleAt(double depth) {
    final t = _perspective(depth);
    return 0.18 + 0.82 * t;
  }

  double laneWidth(double depth) {
    final t = _perspective(depth);
    return size.width * 0.28 * t;
  }

  /// Smooth ease so far field packs denser (readable approach).
  double _perspective(double depth) {
    final d = depth.clamp(0.0, 1.0);
    return math.pow(d, 1.25).toDouble();
  }
}
