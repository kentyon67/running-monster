class FriendCard {
  final String id;
  final String username;
  final String monsterName;
  final int monsterLevel;
  final String monsterImageId;
  final double totalDistanceKm;
  final double weeklyDistanceKm;
  final String? title;
  final String? banner;
  final String? frame;
  final String? aura;
  final String qrData;
  final DateTime importedAt;

  const FriendCard({
    required this.id,
    required this.username,
    required this.monsterName,
    required this.monsterLevel,
    required this.monsterImageId,
    required this.totalDistanceKm,
    required this.weeklyDistanceKm,
    this.title,
    this.banner,
    this.frame,
    this.aura,
    required this.qrData,
    required this.importedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'monsterName': monsterName,
        'monsterLevel': monsterLevel,
        'monsterImageId': monsterImageId,
        'totalDistanceKm': totalDistanceKm,
        'weeklyDistanceKm': weeklyDistanceKm,
        'title': title,
        'banner': banner,
        'frame': frame,
        'aura': aura,
        'qrData': qrData,
        'importedAt': importedAt.millisecondsSinceEpoch,
      };

  factory FriendCard.fromMap(Map<dynamic, dynamic> m) => FriendCard(
        id: m['id'] as String,
        username: m['username'] as String,
        monsterName: m['monsterName'] as String,
        monsterLevel: m['monsterLevel'] as int,
        monsterImageId: m['monsterImageId'] as String,
        totalDistanceKm: (m['totalDistanceKm'] as num).toDouble(),
        weeklyDistanceKm: (m['weeklyDistanceKm'] as num).toDouble(),
        title: m['title'] as String?,
        banner: m['banner'] as String?,
        frame: m['frame'] as String?,
        aura: m['aura'] as String?,
        qrData: m['qrData'] as String,
        importedAt:
            DateTime.fromMillisecondsSinceEpoch(m['importedAt'] as int),
      );
}
