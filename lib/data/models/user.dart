class User {
  final String id;
  String username;
  final DateTime createdAt;
  double totalDistanceKm;
  double weeklyDistanceKm;
  int currentCoins;
  String? selectedTitle;
  String? selectedBanner;
  String? selectedFrame;
  bool notificationEnabled;
  DateTime lastWeeklyResetDate; // Monday of the last reset
  int resetCount;

  User({
    required this.id,
    required this.username,
    required this.createdAt,
    this.totalDistanceKm = 0.0,
    this.weeklyDistanceKm = 0.0,
    this.currentCoins = 0,
    this.selectedTitle,
    this.selectedBanner,
    this.selectedFrame,
    this.notificationEnabled = true,
    required this.lastWeeklyResetDate,
    this.resetCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'totalDistanceKm': totalDistanceKm,
        'weeklyDistanceKm': weeklyDistanceKm,
        'currentCoins': currentCoins,
        'selectedTitle': selectedTitle,
        'selectedBanner': selectedBanner,
        'selectedFrame': selectedFrame,
        'notificationEnabled': notificationEnabled,
        'lastWeeklyResetDate': lastWeeklyResetDate.millisecondsSinceEpoch,
        'resetCount': resetCount,
      };

  factory User.fromMap(Map<dynamic, dynamic> m) => User(
        id: m['id'] as String,
        username: m['username'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        totalDistanceKm: (m['totalDistanceKm'] as num).toDouble(),
        weeklyDistanceKm: (m['weeklyDistanceKm'] as num).toDouble(),
        currentCoins: m['currentCoins'] as int,
        selectedTitle: m['selectedTitle'] as String?,
        selectedBanner: m['selectedBanner'] as String?,
        selectedFrame: m['selectedFrame'] as String?,
        notificationEnabled: m['notificationEnabled'] as bool? ?? true,
        lastWeeklyResetDate: DateTime.fromMillisecondsSinceEpoch(
            m['lastWeeklyResetDate'] as int),
        resetCount: m['resetCount'] as int? ?? 0,
      );

  factory User.initial({required String id}) {
    final now = DateTime.now();
    return User(
      id: id,
      username: 'ランナー',
      createdAt: now,
      lastWeeklyResetDate: _mostRecentMonday(now),
    );
  }

  /// Returns the most recent Monday (at midnight) on or before [date].
  static DateTime _mostRecentMonday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final weekday = d.weekday; // Mon=1, Sun=7
    return d.subtract(Duration(days: weekday - 1));
  }
}
