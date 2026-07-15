import 'package:flame/camera.dart';
import 'package:flame/extensions.dart';

/// Fixed world resolution stretched to fill the whole canvas — no letterbox bars.
class FillResolutionViewport extends Viewport {
  FillResolutionViewport({required this.resolution});

  final Vector2 resolution;
  final Vector2 _scaleVector = Vector2.zero();

  @override
  Vector2 get virtualSize => resolution;

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
    _scaleVector.setValues(size.x / resolution.x, size.y / resolution.y);
    // ignore: invalid_use_of_internal_member
    transform.scale = _scaleVector;
    // ignore: invalid_use_of_internal_member
    camera.viewfinder.visibleRect = null;
  }

  @override
  void clip(Canvas canvas) {
    canvas.clipRect(Offset.zero & Size(size.x, size.y), doAntiAlias: false);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.y >= 0 &&
        point.x <= virtualSize.x &&
        point.y <= virtualSize.y;
  }

  @override
  Vector2 globalToLocal(Vector2 point, {Vector2? output}) {
    final viewportPoint = super.globalToLocal(point, output: output);
    // ignore: invalid_use_of_internal_member
    return transform.globalToLocal(viewportPoint, output: output);
  }

  @override
  Vector2 localToGlobal(Vector2 point, {Vector2? output}) {
    // ignore: invalid_use_of_internal_member
    final viewportPoint = transform.localToGlobal(point, output: output);
    return super.localToGlobal(viewportPoint, output: output);
  }

  @override
  void transformCanvas(Canvas canvas) {
    canvas.translate(size.x / 2, size.y / 2);
    super.transformCanvas(canvas);
    canvas.translate(
      -(size.x / 2) / _scaleVector.x,
      -(size.y / 2) / _scaleVector.y,
    );
  }
}
