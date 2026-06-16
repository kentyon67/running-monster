class Monster {
  final String id;
  String name;
  final String color; // 'red' | 'blue' | 'green'
  int level;
  int exp; // total accumulated EXP
  String currentEvolutionId; // e.g. 'runmon_red'
  List<String> evolutionPath; // choices made so far
  bool isEvolutionAvailable;
  int nameChangeRemaining; // starts at 1
  bool skinUnlocked;
  String? selectedSkin;
  String? selectedAura;

  Monster({
    required this.id,
    required this.name,
    required this.color,
    this.level = 1,
    this.exp = 0,
    required this.currentEvolutionId,
    List<String>? evolutionPath,
    this.isEvolutionAvailable = false,
    this.nameChangeRemaining = 1,
    this.skinUnlocked = false,
    this.selectedSkin,
    this.selectedAura,
  }) : evolutionPath = evolutionPath ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'level': level,
        'exp': exp,
        'currentEvolutionId': currentEvolutionId,
        'evolutionPath': evolutionPath,
        'isEvolutionAvailable': isEvolutionAvailable,
        'nameChangeRemaining': nameChangeRemaining,
        'skinUnlocked': skinUnlocked,
        'selectedSkin': selectedSkin,
        'selectedAura': selectedAura,
      };

  factory Monster.fromMap(Map<dynamic, dynamic> m) => Monster(
        id: m['id'] as String,
        name: m['name'] as String,
        color: m['color'] as String,
        level: m['level'] as int,
        exp: m['exp'] as int,
        currentEvolutionId: m['currentEvolutionId'] as String,
        evolutionPath: List<String>.from(m['evolutionPath'] as List? ?? []),
        isEvolutionAvailable: m['isEvolutionAvailable'] as bool? ?? false,
        nameChangeRemaining: m['nameChangeRemaining'] as int? ?? 1,
        skinUnlocked: m['skinUnlocked'] as bool? ?? false,
        selectedSkin: m['selectedSkin'] as String?,
        selectedAura: m['selectedAura'] as String?,
      );

  factory Monster.initial({
    required String id,
    required String color,
  }) =>
      Monster(
        id: id,
        name: 'ランモン',
        color: color,
        currentEvolutionId: 'runmon',
      );
}
