class GachaItem {
  final String id;
  final String type; // 'skin' | 'aura' | 'banner' | 'frame'
  final String rarity; // 'N' | 'R' | 'SR' | 'SSR'
  final String name;
  final String description;
  bool owned;
  final String source; // 'gacha' | 'achievement' | 'default'

  GachaItem({
    required this.id,
    required this.type,
    required this.rarity,
    required this.name,
    required this.description,
    this.owned = false,
    required this.source,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'rarity': rarity,
        'name': name,
        'description': description,
        'owned': owned,
        'source': source,
      };

  factory GachaItem.fromMap(Map<dynamic, dynamic> m) => GachaItem(
        id: m['id'] as String,
        type: m['type'] as String,
        rarity: m['rarity'] as String,
        name: m['name'] as String,
        description: m['description'] as String,
        owned: m['owned'] as bool? ?? false,
        source: m['source'] as String,
      );
}
