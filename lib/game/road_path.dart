import 'dart:math' as math;
import 'dart:ui';

/// World-space road the ball flies along (side-scroller).
class RoadPath {
  final List<Offset> points = [];

  static const minDist = 6.0;

  void clear() => points.clear();

  bool get hasPoints => points.isNotEmpty;

  /// [allowBack] softens reject so hold-draw doesn't break.
  bool addWorldPoint(Offset p, {bool force = false}) {
    if (points.isEmpty) {
      points.add(p);
      return true;
    }
    final last = points.last;
    final dist = (p - last).distance;
    if (!force && dist < minDist) return false;

    // Prefer forward; if slightly behind, nudge forward instead of drop.
    var next = p;
    if (next.dx < last.dx) {
      next = Offset(last.dx + (force ? 4 : 2), next.dy);
    }
    if (!force && (next - last).distance < minDist) return false;

    points.add(next);
    return true;
  }

  /// Sharpness 0..1 versus previous segment.
  double turnSharpnessAtEnd(Offset next) {
    if (points.length < 2) return 0;
    final a = points[points.length - 2];
    final b = points.last;
    final v1 = Offset(b.dx - a.dx, b.dy - a.dy);
    final v2 = Offset(next.dx - b.dx, next.dy - b.dy);
    final l1 = v1.distance;
    final l2 = v2.distance;
    if (l1 < 0.001 || l2 < 0.001) return 0;
    final dot = ((v1.dx * v2.dx + v1.dy * v2.dy) / (l1 * l2)).clamp(-1.0, 1.0);
    final ang = math.acos(dot); // 0..pi
    return (ang / math.pi).clamp(0.0, 1.0);
  }

  void ensureRunway({
    required double fromX,
    required double toX,
    required double y,
    double step = 40,
  }) {
    if (points.isEmpty) {
      points.add(Offset(fromX, y));
    }
    var x = points.last.dx;
    while (x < toX) {
      x += step;
      points.add(Offset(x, y));
    }
  }

  double? heightAt(double worldX, {double maxGap = 52, double pastExtrapolate = 140}) {
    if (points.isEmpty) return null;
    if (points.length == 1) {
      return (worldX - points.first.dx).abs() <= maxGap ? points.first.dy : null;
    }

    Offset? left;
    Offset? right;
    for (final p in points) {
      if (p.dx <= worldX) left = p;
      if (p.dx >= worldX) {
        right = p;
        break;
      }
    }

    if (left == null && right != null) {
      return (right.dx - worldX) <= maxGap ? right.dy : null;
    }
    if (right == null && left != null) {
      final last = points.last;
      final beyond = worldX - last.dx;
      if (beyond <= maxGap) return last.dy;
      // Grace past the drawn tip — continue last segment slope briefly
      if (beyond <= pastExtrapolate && points.length >= 2) {
        final prev = points[points.length - 2];
        final dx = last.dx - prev.dx;
        if (dx.abs() > 0.001) {
          final slope = (last.dy - prev.dy) / dx;
          return last.dy + slope * beyond;
        }
        return last.dy;
      }
      return null;
    }
    if (left == null || right == null) return null;

    final span = right.dx - left.dx;
    if (span > maxGap * 2.2) {
      if (worldX > left.dx + maxGap && worldX < right.dx - maxGap) {
        return null;
      }
    }
    if (span < 0.0001) return left.dy;
    final t = ((worldX - left.dx) / span).clamp(0.0, 1.0);
    return left.dy + (right.dy - left.dy) * t;
  }

  double aheadOf(double worldX) {
    if (points.isEmpty) return 0;
    return (points.last.dx - worldX).clamp(0.0, 99999);
  }

  Path toScreenPath(double cameraX) {
    final path = Path();
    var started = false;
    for (final p in points) {
      final sx = p.dx - cameraX;
      if (!started) {
        path.moveTo(sx, p.dy);
        started = true;
      } else {
        path.lineTo(sx, p.dy);
      }
    }
    return path;
  }

  Path fakeScreenPath(double cameraX, double time, {double amp = 20}) {
    final path = Path();
    var started = false;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final wobble = math.sin(time * 2.2 + i * 0.35) * amp;
      final sx = p.dx - cameraX;
      final sy = p.dy + wobble;
      if (!started) {
        path.moveTo(sx, sy);
        started = true;
      } else {
        path.lineTo(sx, sy);
      }
    }
    return path;
  }
}
