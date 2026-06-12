class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  factory RoutePoint.fromMap(Map<dynamic, dynamic> m) => RoutePoint(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lng'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int),
      );
}
