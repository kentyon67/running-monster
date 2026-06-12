import 'route_point.dart';

class RunRecord {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final int durationSeconds;
  final double averagePace; // min/km
  final int expGained;
  final int coinsGained;
  final double appliedBonus; // multiplier applied
  final List<RoutePoint> routePoints;

  const RunRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averagePace,
    required this.expGained,
    required this.coinsGained,
    required this.appliedBonus,
    required this.routePoints,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'endedAt': endedAt.millisecondsSinceEpoch,
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
        'averagePace': averagePace,
        'expGained': expGained,
        'coinsGained': coinsGained,
        'appliedBonus': appliedBonus,
        'routePoints': routePoints.map((p) => p.toMap()).toList(),
      };

  factory RunRecord.fromMap(Map<dynamic, dynamic> m) => RunRecord(
        id: m['id'] as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(m['startedAt'] as int),
        endedAt: DateTime.fromMillisecondsSinceEpoch(m['endedAt'] as int),
        distanceKm: (m['distanceKm'] as num).toDouble(),
        durationSeconds: m['durationSeconds'] as int,
        averagePace: (m['averagePace'] as num).toDouble(),
        expGained: m['expGained'] as int,
        coinsGained: m['coinsGained'] as int,
        appliedBonus: (m['appliedBonus'] as num).toDouble(),
        routePoints: (m['routePoints'] as List)
            .map((p) => RoutePoint.fromMap(p as Map))
            .toList(),
      );
}
