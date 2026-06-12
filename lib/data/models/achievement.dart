class Achievement {
  final String id;
  final String category;
  final String title;
  final String description;
  final Map<String, dynamic> condition;
  final String rewardType; // 'coins' | 'title' | 'aura' | 'banner' | 'frame' | 'skin'
  final dynamic rewardValue;
  bool isCompleted;
  DateTime? completedAt;

  Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.condition,
    required this.rewardType,
    required this.rewardValue,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'title': title,
        'description': description,
        'condition': condition,
        'rewardType': rewardType,
        'rewardValue': rewardValue,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.millisecondsSinceEpoch,
      };

  factory Achievement.fromMap(Map<dynamic, dynamic> m) => Achievement(
        id: m['id'] as String,
        category: m['category'] as String,
        title: m['title'] as String,
        description: m['description'] as String,
        condition: Map<String, dynamic>.from(m['condition'] as Map),
        rewardType: m['rewardType'] as String,
        rewardValue: m['rewardValue'],
        isCompleted: m['isCompleted'] as bool? ?? false,
        completedAt: m['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['completedAt'] as int)
            : null,
      );
}
