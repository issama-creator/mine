import 'dart:ui';

import '../components/falling_object.dart';

class _TrailPoint {
  _TrailPoint(this.pos, this.age);
  Offset pos;
  double age;
}

/// Line-segment vs circle slice collision + fading trail.
class SliceSystem {
  static const fadeSeconds = 0.25;

  final List<Offset> _points = [];
  final List<_TrailPoint> _fadeTrail = [];

  void begin(Offset p) {
    _points
      ..clear()
      ..add(p);
    _fadeTrail.add(_TrailPoint(p, 0));
  }

  void add(Offset p) {
    if (_points.isEmpty) {
      _points.add(p);
      _fadeTrail.add(_TrailPoint(p, 0));
      return;
    }
    final last = _points.last;
    if ((last - p).distance > 5) {
      _points.add(p);
      _fadeTrail.add(_TrailPoint(p, 0));
    }
  }

  void end() => _points.clear();

  void tickFade(double dt) {
    for (final pt in _fadeTrail) {
      pt.age += dt;
    }
    _fadeTrail.removeWhere((p) => p.age > fadeSeconds);
  }

  int testSlice(FallingObject obj) {
    if (_points.length < 2) return 0;
    var hits = 0;
    for (var i = 1; i < _points.length; i++) {
      if (_segmentHitsCircle(
        _points[i - 1],
        _points[i],
        Offset(obj.position.x, obj.position.y),
        obj.hitRadius,
      )) {
        hits++;
        final center = Offset(obj.position.x, obj.position.y);
        final mid = Offset(
          (_points[i - 1].dx + _points[i].dx) / 2,
          (_points[i - 1].dy + _points[i].dy) / 2,
        );
        final perfect = (mid - center).distance < obj.hitRadius * 0.35;
        obj.slice(perfect: perfect);
        if (obj.dead) break;
      }
    }
    return hits;
  }

  bool _segmentHitsCircle(Offset a, Offset b, Offset c, double r) {
    final ab = b - a;
    final ac = c - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1) return ac.distance <= r;
    var t = (ac.dx * ab.dx + ac.dy * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (closest - c).distance <= r;
  }

  List<Offset> get trail => List.unmodifiable(_points);

  List<({Offset pos, double alpha, double width})> get fadedTrail {
    return [
      for (final p in _fadeTrail)
        (
          pos: p.pos,
          alpha: (1 - p.age / fadeSeconds).clamp(0.0, 1.0),
          width: 3.2 + (1 - p.age / fadeSeconds) * 5.5,
        ),
    ];
  }
}
