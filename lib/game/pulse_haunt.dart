import 'dart:convert';

import 'components/hazard.dart';

/// A ghost of your last death — hunt it in the next run.
class HauntRecord {
  const HauntRecord({
    required this.id,
    required this.kind,
    required this.lane,
    required this.deathMeters,
    required this.power,
    required this.name,
    this.capturedAt,
  });

  final String id;
  final String kind;
  final int lane;
  final int deathMeters;
  final int power;
  final String name;
  final int? capturedAt;

  bool get isCaptured => capturedAt != null;

  HazardKind get hazardKind => HazardKind.values.firstWhere(
        (k) => k.name == kind,
        orElse: () => HazardKind.wall,
      );

  static HauntRecord fromDeath({
    required HazardKind kind,
    required int lane,
    required int meters,
    int power = 1,
  }) {
    return HauntRecord(
      id: '${kind.name}_${lane}_$meters',
      kind: kind.name,
      lane: lane,
      deathMeters: meters,
      power: power,
      name: _nameFor(kind, lane, meters),
    );
  }

  HauntRecord withPower(int p) => HauntRecord(
        id: id,
        kind: kind,
        lane: lane,
        deathMeters: deathMeters,
        power: p,
        name: name,
        capturedAt: capturedAt,
      );

  HauntRecord captured(int atMeters) => HauntRecord(
        id: id,
        kind: kind,
        lane: lane,
        deathMeters: deathMeters,
        power: power,
        name: name,
        capturedAt: atMeters,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'lane': lane,
        'deathMeters': deathMeters,
        'power': power,
        'name': name,
        'capturedAt': capturedAt,
      };

  factory HauntRecord.fromJson(Map<String, dynamic> j) => HauntRecord(
        id: j['id'] as String,
        kind: j['kind'] as String,
        lane: j['lane'] as int,
        deathMeters: j['deathMeters'] as int,
        power: j['power'] as int? ?? 1,
        name: j['name'] as String,
        capturedAt: j['capturedAt'] as int?,
      );

  static String _nameFor(HazardKind kind, int lane, int m) => switch (kind) {
        HazardKind.wall => '✕ полоса $lane · $m m',
        HazardKind.gate => 'HOLD щель · $m m',
        HazardKind.brittle => 'SMASH стекло · $m m',
        HazardKind.fakeWall => 'Ловушка · $m m',
        _ => 'Призрак · $m m',
      };

  static List<HauntRecord> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => HauntRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<HauntRecord> list) =>
      jsonEncode(list.map((h) => h.toJson()).toList());
}
