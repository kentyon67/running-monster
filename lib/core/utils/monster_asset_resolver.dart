class MonsterAssetResolver {
  // Add keys here as PNG assets land in assets/monsters/
  // Key format: 'evolutionId/color' or 'evolutionId' for color-agnostic
  // Skin key format: 'evolutionId/skins/skinName'
  static const Set<String> _availableAssets = {};

  static String? resolvePath(
    String evolutionId,
    String color, {
    String? selectedSkin,
  }) {
    if (selectedSkin != null) {
      final skinKey = '$evolutionId/skins/$selectedSkin';
      if (_availableAssets.contains(skinKey)) {
        return 'assets/monsters/$evolutionId/skins/$selectedSkin/idle.png';
      }
    }
    final colorKey = '$evolutionId/$color';
    if (_availableAssets.contains(colorKey)) {
      return 'assets/monsters/$evolutionId/$color/idle.png';
    }
    if (_availableAssets.contains(evolutionId)) {
      return 'assets/monsters/$evolutionId/idle.png';
    }
    return null;
  }

  static bool hasAsset(String evolutionId, String color, {String? selectedSkin}) =>
      resolvePath(evolutionId, color, selectedSkin: selectedSkin) != null;
}
