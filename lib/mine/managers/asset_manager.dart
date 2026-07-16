import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/game_config.dart';
import '../models/mine_background.dart';
import '../models/object_kind.dart';

/// Loads PNGs and auto-compensates size, padding, pivot, and frame drift.
class AssetManager {
  AssetManager._();
  static final AssetManager instance = AssetManager._();

  bool _ready = false;
  List<Sprite> runFrames = [];
  double _runFrameScale = 1;
  int runFrameCount = 0;
  Sprite? spider;
  Sprite? bossSpider;
  Sprite? objRock;
  Sprite? objCrate;
  Sprite? objCrystal;
  Sprite? objDynamite;
  Sprite? objSaw;
  Sprite? objSpikeBlock;
  final List<Sprite> mineBackgrounds = [];
  Sprite? bgMain;

  final Map<String, Vector2> _visualCenters = {};
  final List<ui.Image> _ownedImages = [];

  bool get isReady => _ready;

  /// Seconds per run frame for a natural runner cadence.
  double get runStepSeconds {
    final n = runFrameCount <= 0 ? 10 : runFrameCount;
    return GameConfig.runCycleSeconds / n;
  }

  void reset() {
    _ready = false;
    for (final img in _ownedImages) {
      img.dispose();
    }
    _ownedImages.clear();
    runFrames = [];
    runFrameCount = 0;
    mineBackgrounds.clear();
  }

  Future<List<String>> _discoverRunPaths() async {
    try {
      final raw = await rootBundle.loadString('AssetManifest.json');
      final map = json.decode(raw) as Map<String, dynamic>;
      final keys = map.keys
          .where((k) =>
              k.startsWith('assets/player/run_') && k.endsWith('.png'))
          .toList()
        ..sort();
      if (keys.isNotEmpty) {
        return keys.map((k) => k.replaceFirst('assets/', '')).toList();
      }
    } catch (_) {}
    // Fallback: run_01 … run_32
    final found = <String>[];
    for (var i = 1; i <= 32; i++) {
      final path = 'player/run_${i.toString().padLeft(2, '0')}.png';
      try {
        await Flame.images.load(path);
        found.add(path);
      } catch (_) {
        break;
      }
    }
    return found;
  }

  Future<void> loadAll() async {
    if (_ready) return;
    Flame.images.prefix = 'assets/';

    final runPaths = await _discoverRunPaths();
    if (runPaths.isEmpty) {
      throw StateError('No player/run_*.png assets found');
    }

    await Flame.images.loadAll([
      ...runPaths,
      'animals/spider.png',
      'animals/spiderbig2taps.png',
      'objekts/rock.png',
      'objekts/crate.png',
      'objekts/crystal.png',
      'objekts/dynamite.png',
      'objekts/saw.png',
      'objekts/spike_block.png',
      ...MineBackground.paths,
    ]);

    final cleaned = <ui.Image>[];
    for (final path in runPaths) {
      final img = await _cleanRunFrame(Flame.images.fromCache(path));
      cleaned.add(img);
    }

    // Bottom-align all frames to one canvas so feet never jitter (runner feel).
    final unified = await _unifyRunFrames(cleaned);
    for (final img in cleaned) {
      img.dispose();
    }
    _ownedImages.addAll(unified);

    runFrames = [for (final img in unified) Sprite(img)];
    runFrameCount = runFrames.length;

    spider = Sprite(Flame.images.fromCache('animals/spider.png'));
    bossSpider = Sprite(Flame.images.fromCache('animals/spiderbig2taps.png'));
    objRock = Sprite(Flame.images.fromCache('objekts/rock.png'));
    objCrate = Sprite(Flame.images.fromCache('objekts/crate.png'));
    objCrystal = Sprite(Flame.images.fromCache('objekts/crystal.png'));
    objDynamite = Sprite(Flame.images.fromCache('objekts/dynamite.png'));
    objSaw = Sprite(Flame.images.fromCache('objekts/saw.png'));
    objSpikeBlock = Sprite(Flame.images.fromCache('objekts/spike_block.png'));
    mineBackgrounds.addAll([
      for (final path in MineBackground.paths)
        Sprite(Flame.images.fromCache(path)),
    ]);
    bgMain = mineBackgrounds.isNotEmpty ? mineBackgrounds.first : null;

    _normalizeRunScale();
    await _cacheVisualCenters();

    _ready = true;
  }

  /// Pad frames to shared size with feet locked to the bottom edge.
  Future<List<ui.Image>> _unifyRunFrames(List<ui.Image> frames) async {
    var maxW = 1;
    var maxH = 1;
    for (final f in frames) {
      if (f.width > maxW) maxW = f.width;
      if (f.height > maxH) maxH = f.height;
    }

    final out = <ui.Image>[];
    for (final f in frames) {
      final bd = await f.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) {
        out.add(f);
        continue;
      }
      final src = bd.buffer.asUint8List();
      final dst = Uint8List(maxW * maxH * 4);
      final ox = ((maxW - f.width) / 2).floor();
      final oy = maxH - f.height; // feet on bottom
      for (var y = 0; y < f.height; y++) {
        for (var x = 0; x < f.width; x++) {
          final si = (y * f.width + x) * 4;
          final di = ((y + oy) * maxW + (x + ox)) * 4;
          dst[di] = src[si];
          dst[di + 1] = src[si + 1];
          dst[di + 2] = src[si + 2];
          dst[di + 3] = src[si + 3];
        }
      }
      final c = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        dst,
        maxW,
        maxH,
        ui.PixelFormat.rgba8888,
        c.complete,
      );
      out.add(await c.future);
    }
    return out;
  }

  void _normalizeRunScale() {
    if (runFrames.isEmpty) {
      _runFrameScale = 1;
      return;
    }
    var maxH = 1.0;
    for (final s in runFrames) {
      if (s.srcSize.y > maxH) maxH = s.srcSize.y;
    }
    _runFrameScale = GameConfig.minerTargetHeight / maxH;
  }

  Future<void> _cacheVisualCenters() async {
    if (kIsWeb) return;
    final pairs = <(String, Sprite?)>[
      ('spider', spider),
      ('boss', bossSpider),
      ('obj_rock', objRock),
      ('obj_crate', objCrate),
      ('obj_crystal', objCrystal),
      ('obj_dynamite', objDynamite),
      ('obj_saw', objSaw),
      ('obj_spike', objSpikeBlock),
    ];
    for (final (key, spr) in pairs) {
      if (spr == null) continue;
      final b = await _visualBounds(spr.image);
      _visualCenters[key] = Vector2(b.center.dx, b.center.dy);
    }
  }

  /// Removes black/checker bg, filename labels under feet, then crops to soles.
  Future<ui.Image> _cleanRunFrame(ui.Image src) async {
    final bd = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return src;

    final w = src.width;
    final h = src.height;
    final px = Uint8List.fromList(bd.buffer.asUint8List());

    int chroma(int r, int g, int b) =>
        math.max(r, math.max(g, b)) - math.min(r, math.min(g, b));
    double avg(int r, int g, int b) => (r + g + b) / 3.0;

    bool isBg(int r, int g, int b, int a) {
      if (a < 20) return true;
      if (math.max(r, math.max(g, b)) < 28) return true;
      return avg(r, g, b) >= 220 && chroma(r, g, b) <= 30;
    }

    bool isLabelish(int r, int g, int b, int a) {
      if (a < 20) return false;
      return avg(r, g, b) >= 100 && chroma(r, g, b) <= 40;
    }

    bool isColoredBody(int r, int g, int b, int a) {
      if (a < 35 || isBg(r, g, b, a)) return false;
      return chroma(r, g, b) >= 22 && avg(r, g, b) < 245;
    }

    for (var i = 0; i < w * h; i++) {
      final p = i * 4;
      if (isBg(px[p], px[p + 1], px[p + 2], px[p + 3])) {
        px[p + 3] = 0;
      }
    }

    final labelY0 = (h * 0.72).floor();
    for (var y = labelY0; y < h; y++) {
      final labelXs = <int>[];
      for (var x = 0; x < w; x++) {
        final p = (y * w + x) * 4;
        if (isLabelish(px[p], px[p + 1], px[p + 2], px[p + 3])) {
          labelXs.add(x);
        }
      }
      if (labelXs.length >= 10) {
        for (final x in labelXs) {
          px[(y * w + x) * 4 + 3] = 0;
        }
      }
      if (y >= (h * 0.88).floor()) {
        for (var x = 0; x < w; x++) {
          final p = (y * w + x) * 4;
          if (px[p + 3] > 0 && chroma(px[p], px[p + 1], px[p + 2]) <= 45) {
            px[p + 3] = 0;
          }
        }
      }
    }

    var feetY = 0;
    for (var y = 0; y < h; y++) {
      var body = 0;
      for (var x = 0; x < w; x++) {
        final p = (y * w + x) * 4;
        if (isColoredBody(px[p], px[p + 1], px[p + 2], px[p + 3])) body++;
      }
      if (body >= 6) feetY = y;
    }
    if (feetY < h * 0.3) feetY = (h * 0.8).floor().clamp(0, h - 1);

    // Flush soles to bottom of frame — no shadow padding under boots
    // (that padding made Anchor.bottomCenter sit below the visible feet).
    for (var y = feetY + 1; y < h; y++) {
      for (var x = 0; x < w; x++) {
        px[(y * w + x) * 4 + 3] = 0;
      }
    }

    var minX = w;
    var minY = h;
    var maxX = 0;
    for (var y = 0; y <= feetY; y++) {
      for (var x = 0; x < w; x++) {
        final p = (y * w + x) * 4;
        if (px[p + 3] > 28) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
        }
      }
    }
    if (maxX <= minX) {
      minX = 0;
      maxX = w - 1;
      minY = 0;
    }

    final outW = (maxX - minX + 1).clamp(1, w);
    final outH = (feetY - minY + 1).clamp(1, h - minY);
    final out = Uint8List(outW * outH * 4);

    for (var y = 0; y < outH; y++) {
      final srcY = minY + y;
      for (var x = 0; x < outW; x++) {
        final srcX = minX + x;
        final si = (srcY * w + srcX) * 4;
        final di = (y * outW + x) * 4;
        out[di] = px[si];
        out[di + 1] = px[si + 1];
        out[di + 2] = px[si + 2];
        out[di + 3] = px[si + 3];
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      out,
      outW,
      outH,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<Rect> _visualBounds(ui.Image img) async {
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) {
      return Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    }
    final w = img.width;
    final h = img.height;
    var minX = w;
    var minY = h;
    var maxX = 0;
    var maxY = 0;
    for (var y = 0; y < h; y += 2) {
      for (var x = 0; x < w; x += 2) {
        final a = bd.getUint8((y * w + x) * 4 + 3);
        if (a > 20) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX <= minX) {
      return Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    }
    return Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      (maxX + 1).toDouble(),
      (maxY + 1).toDouble(),
    );
  }

  Sprite? bgAtIndex(int index) {
    if (mineBackgrounds.isEmpty) return bgMain;
    return mineBackgrounds[index % mineBackgrounds.length];
  }

  double scaleFor(Sprite sprite, double targetHeight) {
    final h = sprite.srcSize.y;
    if (h <= 0) return 1;
    return targetHeight / h;
  }

  double runFrameScale(Sprite frame) => _runFrameScale;

  Sprite? spriteFor(ObjectKind kind) => switch (kind) {
        ObjectKind.rockSmall ||
        ObjectKind.rockMedium ||
        ObjectKind.rockLarge ||
        ObjectKind.objRock =>
          objRock,
        ObjectKind.spider => spider,
        ObjectKind.bossSpider => bossSpider,
        ObjectKind.objCrate => objCrate,
        ObjectKind.objCrystal => objCrystal,
        ObjectKind.objDynamite => objDynamite,
        ObjectKind.objSaw => objSaw,
        ObjectKind.objSpikeBlock => objSpikeBlock,
        _ => null,
      };

  double normalizedScale(ObjectKind kind, Sprite sprite) {
    final key = switch (kind) {
      ObjectKind.spider => 'spider',
      ObjectKind.bossSpider => 'boss',
      ObjectKind.rockSmall ||
      ObjectKind.rockMedium ||
      ObjectKind.rockLarge ||
      ObjectKind.objRock =>
        'obj_rock',
      ObjectKind.objCrate => 'obj_crate',
      ObjectKind.objCrystal => 'obj_crystal',
      ObjectKind.objDynamite => 'obj_dynamite',
      ObjectKind.objSaw => 'obj_saw',
      ObjectKind.objSpikeBlock => 'obj_spike',
      _ => '',
    };
    final bounds = _visualCenters[key];
    if (bounds != null && bounds.y > 0) {
      final visualH = sprite.srcSize.y * 0.85;
      return scaleFor(sprite, kind.targetHeight) *
          (sprite.srcSize.y / visualH).clamp(0.85, 1.15);
    }
    return scaleFor(sprite, kind.targetHeight);
  }

  void drawProcedural(Canvas canvas, ObjectKind kind, double scale) {
    final s = scale.clamp(0.4, 2.5);
    switch (kind) {
      case ObjectKind.diamond:
        final path = Path()
          ..moveTo(0, -20 * s)
          ..lineTo(16 * s, 0)
          ..lineTo(0, 20 * s)
          ..lineTo(-16 * s, 0)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF80DEEA), Color(0xFF00ACC1)],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: 20 * s)),
        );
      case ObjectKind.goldNugget:
        canvas.drawCircle(
          Offset.zero,
          18 * s,
          Paint()..color = const Color(0xFFFFD54F),
        );
      case ObjectKind.dynamite:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 36 * s, height: 16 * s),
            Radius.circular(4 * s),
          ),
          Paint()..color = const Color(0xFFD32F2F),
        );
        canvas.drawCircle(
          Offset(0, -14 * s),
          4 * s,
          Paint()..color = const Color(0xFFFFEB3B),
        );
      case ObjectKind.woodBeam:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 48 * s, height: 14 * s),
            Radius.circular(3 * s),
          ),
          Paint()..color = const Color(0xFF6D4C41),
        );
      case ObjectKind.debris:
        canvas.drawCircle(
          Offset.zero,
          14 * s,
          Paint()..color = const Color(0xFF78909C),
        );
      case ObjectKind.stalactite:
        final tip = Path()
          ..moveTo(0, 28 * s)
          ..lineTo(14 * s, -26 * s)
          ..lineTo(6 * s, -22 * s)
          ..lineTo(0, -30 * s)
          ..lineTo(-7 * s, -20 * s)
          ..lineTo(-15 * s, -26 * s)
          ..close();
        canvas.drawPath(
          tip,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB0BEC5), Color(0xFF546E7A), Color(0xFF37474F)],
            ).createShader(Rect.fromCenter(
              center: Offset.zero,
              width: 36 * s,
              height: 60 * s,
            )),
        );
        canvas.drawPath(
          tip,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4 * s
            ..color = const Color(0xFF263238),
        );
        // Ice highlight
        canvas.drawLine(
          Offset(-4 * s, -10 * s),
          Offset(-2 * s, 12 * s),
          Paint()
            ..color = const Color(0xAAE0F7FA)
            ..strokeWidth = 2 * s
            ..strokeCap = StrokeCap.round,
        );
      case ObjectKind.pathSpike:
        // Bottom-anchored: base on y≈0 (path), tips point up (negative Y).
        for (final ox in [-18.0, 0.0, 18.0]) {
          final spike = Path()
            ..moveTo((ox - 11) * s, 0)
            ..lineTo(ox * s, -34 * s)
            ..lineTo((ox + 11) * s, 0)
            ..close();
          canvas.drawPath(
            spike,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Color(0xFFD7CCC8),
                  Color(0xFF8D6E63),
                  Color(0xFF3E2723),
                ],
              ).createShader(Rect.fromCenter(
                center: Offset(ox * s, -16 * s),
                width: 24 * s,
                height: 36 * s,
              )),
          );
          canvas.drawPath(
            spike,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 * s
              ..color = const Color(0xFF1B0F0A),
          );
        }
        // Shadow plate sitting on the cobbles.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, 2 * s),
            width: 58 * s,
            height: 9 * s,
          ),
          Paint()..color = const Color(0x99212121),
        );
      default:
        break;
    }
  }
}
