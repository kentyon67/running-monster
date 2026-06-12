import '../local/hive_boxes.dart';
import '../models/gacha_item.dart';
import '../../core/constants/gacha_data.dart';
import '../../core/utils/gacha_engine.dart';

class GachaRepository {
  List<GachaItem> _cache = [];
  int _totalPulls = 0;

  static const _pullCountKey = 'total_pulls';

  Future<void> load() async {
    final box = HiveBoxes.gachaItems;
    _totalPulls = (box.get(_pullCountKey) as int?) ?? 0;
    _cache = box.keys
        .where((k) => k != _pullCountKey)
        .map((k) => GachaItem.fromMap(box.get(k) as Map))
        .toList();
  }

  List<GachaItem> get ownedItems => _cache.where((i) => i.owned).toList();
  int get totalPulls => _totalPulls;

  bool ownsItem(String id) => _cache.any((i) => i.id == id && i.owned);

  Future<List<GachaItem>> pullGacha(int count) async {
    final results = <GachaItem>[];
    for (var i = 0; i < count; i++) {
      final item = GachaEngine.pull();
      results.add(item);
      if (!ownsItem(item.id)) {
        item.owned = true;
        _cache.removeWhere((e) => e.id == item.id);
        _cache.add(item);
        await HiveBoxes.gachaItems.put(item.id, item.toMap());
      }
    }
    _totalPulls += count;
    await HiveBoxes.gachaItems.put(_pullCountKey, _totalPulls);
    return results;
  }

  Future<void> awardItem(String itemId, String source) async {
    if (ownsItem(itemId)) return;
    final def = kGachaItemDefs.firstWhere(
      (d) => d['id'] == itemId,
      orElse: () => <String, String>{},
    );
    if (def.isEmpty) return;
    final item = GachaItem(
      id: def['id']!,
      type: def['type']!,
      rarity: def['rarity']!,
      name: def['name']!,
      description: def['description']!,
      owned: true,
      source: source,
    );
    _cache.add(item);
    await HiveBoxes.gachaItems.put(item.id, item.toMap());
  }

  List<GachaItem> itemsByType(String type) =>
      _cache.where((i) => i.owned && i.type == type).toList();
}
