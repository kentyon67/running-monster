class DailyMission {
  final String id;
  final DateTime date;
  final String title;
  final Map<String, dynamic> condition;
  final int rewardCoins;
  bool isCompleted;

  DailyMission({
    required this.id,
    required this.date,
    required this.title,
    required this.condition,
    required this.rewardCoins,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'title': title,
        'condition': condition,
        'rewardCoins': rewardCoins,
        'isCompleted': isCompleted,
      };

  factory DailyMission.fromMap(Map<dynamic, dynamic> m) => DailyMission(
        id: m['id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        title: m['title'] as String,
        condition: Map<String, dynamic>.from(m['condition'] as Map),
        rewardCoins: m['rewardCoins'] as int,
        isCompleted: m['isCompleted'] as bool? ?? false,
      );
}
