class EvolutionNode {
  final String id;
  final String name;
  final String emoji;
  final int requiredLevel;
  final List<String> nextEvolutions;
  final String? requiredParent;
  final String description;

  const EvolutionNode({
    required this.id,
    required this.name,
    required this.emoji,
    required this.requiredLevel,
    required this.nextEvolutions,
    this.requiredParent,
    required this.description,
  });
}

const Map<String, EvolutionNode> kEvolutionTree = {
  // Base forms (Lv1)
  'runmon_red': EvolutionNode(
    id: 'runmon_red',
    name: 'ランモン(赤)',
    emoji: '🦊',
    requiredLevel: 1,
    nextEvolutions: ['beastmon', 'spiritmon'],
    description: '走ることが大好きな赤いモンスター',
  ),
  'runmon_blue': EvolutionNode(
    id: 'runmon_blue',
    name: 'ランモン(青)',
    emoji: '🐬',
    requiredLevel: 1,
    nextEvolutions: ['beastmon', 'spiritmon'],
    description: '走ることが大好きな青いモンスター',
  ),
  'runmon_green': EvolutionNode(
    id: 'runmon_green',
    name: 'ランモン(緑)',
    emoji: '🐸',
    requiredLevel: 1,
    nextEvolutions: ['beastmon', 'spiritmon'],
    description: '走ることが大好きな緑のモンスター',
  ),

  // Lv10 evolutions
  'beastmon': EvolutionNode(
    id: 'beastmon',
    name: 'ビーストモン',
    emoji: '🦊',
    requiredLevel: 10,
    nextEvolutions: ['lionmon', 'wolfmon'],
    requiredParent: null,
    description: '野生の力に目覚めた獣系モンスター',
  ),
  'spiritmon': EvolutionNode(
    id: 'spiritmon',
    name: 'スピリットモン',
    emoji: '🦅',
    requiredLevel: 10,
    nextEvolutions: ['phoenixmon', 'dragonmon'],
    requiredParent: null,
    description: '霊的なエネルギーを纏った精霊系モンスター',
  ),

  // Lv20 evolutions
  'lionmon': EvolutionNode(
    id: 'lionmon',
    name: 'ライオンモン',
    emoji: '🦁',
    requiredLevel: 20,
    nextEvolutions: ['leomon', 'kingmon'],
    requiredParent: 'beastmon',
    description: '百獣の王の力を持つ誇り高きモンスター',
  ),
  'wolfmon': EvolutionNode(
    id: 'wolfmon',
    name: 'ウルフモン',
    emoji: '🐺',
    requiredLevel: 20,
    nextEvolutions: ['fenrirmon', 'arcticmon'],
    requiredParent: 'beastmon',
    description: '群れを率いる孤高の狼モンスター',
  ),
  'phoenixmon': EvolutionNode(
    id: 'phoenixmon',
    name: 'フェニックスモン',
    emoji: '🔥',
    requiredLevel: 20,
    nextEvolutions: ['blazemon', 'shadowmon'],
    requiredParent: 'spiritmon',
    description: '炎の翼を持つ不死鳥モンスター',
  ),
  'dragonmon': EvolutionNode(
    id: 'dragonmon',
    name: 'ドラゴンモン',
    emoji: '🐉',
    requiredLevel: 20,
    nextEvolutions: ['stormmon', 'crystalmon'],
    requiredParent: 'spiritmon',
    description: '嵐を呼ぶ龍系モンスター',
  ),

  // Lv30 evolutions
  'leomon': EvolutionNode(
    id: 'leomon',
    name: 'レオモン',
    emoji: '👑',
    requiredLevel: 30,
    nextEvolutions: ['godleomon'],
    requiredParent: 'lionmon',
    description: '神の域に近づいた究極の獅子',
  ),
  'kingmon': EvolutionNode(
    id: 'kingmon',
    name: 'キングモン',
    emoji: '⚔️',
    requiredLevel: 30,
    nextEvolutions: ['emperormon'],
    requiredParent: 'lionmon',
    description: '全ての生き物を統べる王',
  ),
  'fenrirmon': EvolutionNode(
    id: 'fenrirmon',
    name: 'フェンリルモン',
    emoji: '❄️',
    requiredLevel: 30,
    nextEvolutions: ['ragnarokmon'],
    requiredParent: 'wolfmon',
    description: '神話の巨狼。その咆哮は世界を震わす',
  ),
  'arcticmon': EvolutionNode(
    id: 'arcticmon',
    name: 'アークティックモン',
    emoji: '🌨️',
    requiredLevel: 30,
    nextEvolutions: ['glaciermon'],
    requiredParent: 'wolfmon',
    description: '永久凍土から生まれた氷の狼',
  ),
  'blazemon': EvolutionNode(
    id: 'blazemon',
    name: 'ブレイズモン',
    emoji: '🌟',
    requiredLevel: 30,
    nextEvolutions: ['sunbirdmon'],
    requiredParent: 'phoenixmon',
    description: '太陽の炎を操る光の使者',
  ),
  'shadowmon': EvolutionNode(
    id: 'shadowmon',
    name: 'シャドウモン',
    emoji: '🌑',
    requiredLevel: 30,
    nextEvolutions: ['voidmon'],
    requiredParent: 'phoenixmon',
    description: '暗黒のエネルギーを吸収する影のモンスター',
  ),
  'stormmon': EvolutionNode(
    id: 'stormmon',
    name: 'ストームモン',
    emoji: '⚡',
    requiredLevel: 30,
    nextEvolutions: ['skydragonmon'],
    requiredParent: 'dragonmon',
    description: '嵐の化身。空を駆ける雷の龍',
  ),
  'crystalmon': EvolutionNode(
    id: 'crystalmon',
    name: 'クリスタルモン',
    emoji: '💎',
    requiredLevel: 30,
    nextEvolutions: ['prismmon'],
    requiredParent: 'dragonmon',
    description: '純粋なエネルギーで形成された透明な龍',
  ),

  // Lv40 final forms
  'godleomon': EvolutionNode(
    id: 'godleomon',
    name: '神レオモン',
    emoji: '✨',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'leomon',
    description: '究極の境地に達した神の獅子',
  ),
  'emperormon': EvolutionNode(
    id: 'emperormon',
    name: 'エンペラーモン',
    emoji: '🌠',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'kingmon',
    description: '宇宙を統べる皇帝モンスター',
  ),
  'ragnarokmon': EvolutionNode(
    id: 'ragnarokmon',
    name: 'ラグナロクモン',
    emoji: '🌌',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'fenrirmon',
    description: '終末を告げる神話最強の狼神',
  ),
  'glaciermon': EvolutionNode(
    id: 'glaciermon',
    name: 'グレイシャーモン',
    emoji: '🏔️',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'arcticmon',
    description: '氷河を砕く絶対零度の守護者',
  ),
  'sunbirdmon': EvolutionNode(
    id: 'sunbirdmon',
    name: 'サンバードモン',
    emoji: '☀️',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'blazemon',
    description: '太陽そのものと化した究極の光の鳥',
  ),
  'voidmon': EvolutionNode(
    id: 'voidmon',
    name: 'ボイドモン',
    emoji: '🌀',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'shadowmon',
    description: '虚無から生まれた宇宙の深淵',
  ),
  'skydragonmon': EvolutionNode(
    id: 'skydragonmon',
    name: '天龍モン',
    emoji: '🐲',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'stormmon',
    description: '天空を支配する究極の龍神',
  ),
  'prismmon': EvolutionNode(
    id: 'prismmon',
    name: 'プリズムモン',
    emoji: '🌈',
    requiredLevel: 40,
    nextEvolutions: [],
    requiredParent: 'crystalmon',
    description: '全ての光を内包する虹色の龍',
  ),
};

/// Returns the two evolution choices for a monster at the given evolution level.
/// [currentEvolutionId] is the monster's current form.
/// Returns empty list if no evolution available.
List<EvolutionNode> getEvolutionChoices(String currentEvolutionId) {
  final node = kEvolutionTree[currentEvolutionId];
  if (node == null) return [];
  return node.nextEvolutions
      .map((id) => kEvolutionTree[id])
      .whereType<EvolutionNode>()
      .toList();
}
