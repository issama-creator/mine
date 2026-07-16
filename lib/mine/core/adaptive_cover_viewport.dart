import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';

/// Fixed 1280×720 world scaled uniformly to fill any screen (16:9 … 21:9).
/// Crops overflow; keeps the bottom (road + miner feet) pinned to screen bottom.
class AdaptiveCoverViewport extends Viewport implements ReadOnlyScaleProvider {
  AdaptiveCoverViewport({required this.resolution});

  final Vector2 resolution;
  final Vector2 _scaleVector = Vector2.zero();

  double get _scale => _scaleVector.x;

  double get _offsetX => (size.x - resolution.x * _scale) * 0.5;

  /// Bottom-align so [GameConfig.groundY] / road never floats on tall screens.
  double get _offsetY => size.y - resolution.y * _scale;

  @override
  Vector2 get virtualSize => resolution;

  @override
  Vector2 get scale => _scaleVector;

  @override
  void onLoad() {
    size = findGame()!.canvasSize;
    position.setZero();
  }

  @override
  void onGameResize(Vector2 size) {
    this.size = size;
    position.setZero();
    super.onGameResize(size);
  }

  @override
  void onViewportResize() {
    if (size.x < 1 || size.y < 1) {
      _scaleVector.setValues(1, 1);
    } else {
      final sx = size.x / resolution.x;
      final sy = size.y / resolution.y;
      // Uniform cover — no squash/stretch on 18:9 / 20:9 / 21:9 phones.
      _scaleVector.setAll(math.max(sx, sy));
    }
    // ignore: invalid_use_of_internal_member
    transform.scale = _scaleVector;
    // ignore: invalid_use_of_internal_member
    camera.viewfinder.visibleRect = null;
  }

  Vector2 _worldToViewport(Vector2 world, {Vector2? output}) {
    final x = world.x * _scale + _offsetX;
    final y = world.y * _scale + _offsetY;
    return (output?..setValues(x, y)) ?? Vector2(x, y);
  }

  Vector2 _viewportToWorld(Vector2 viewport, {Vector2? output}) {
    final s = _scale <= 0 ? 1.0 : _scale;
    final x = (viewport.x - _offsetX) / s;
    final y = (viewport.y - _offsetY) / s;
    return (output?..setValues(x, y)) ?? Vector2(x, y);
  }

  @override
  void clip(Canvas canvas) {
    canvas.clipRect(Offset.zero & Size(size.x, size.y), doAntiAlias: false);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final w = _viewportToWorld(point);
    return w.x >= 0 &&
        w.y >= 0 &&
        w.x <= resolution.x &&
        w.y <= resolution.y;
  }

  @override
  Vector2 globalToLocal(Vector2 point, {Vector2? output}) {
    final viewportPoint = super.globalToLocal(point, output: output);
    return _viewportToWorld(viewportPoint, output: output);
  }

  @override
  Vector2 localToGlobal(Vector2 point, {Vector2? output}) {
    final viewportPoint = _worldToViewport(point, output: output);
    return super.localToGlobal(viewportPoint, output: output);
  }

  @override
  void transformCanvas(Canvas canvas) {
    canvas.translate(_offsetX, _offsetY);
    canvas.scale(_scale);
  }
}
