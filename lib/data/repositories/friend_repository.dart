import '../local/hive_boxes.dart';
import '../models/friend_card.dart';

class FriendRepository {
  List<FriendCard> _cache = [];

  Future<void> load() async {
    final box = HiveBoxes.friendCards;
    _cache = box.keys
        .map((k) => FriendCard.fromMap(box.get(k) as Map))
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  List<FriendCard> get all => _cache;

  List<FriendCard> get sortedByWeekly =>
      List<FriendCard>.from(_cache)
        ..sort((a, b) => b.weeklyDistanceKm.compareTo(a.weeklyDistanceKm));

  List<FriendCard> get sortedByTotal =>
      List<FriendCard>.from(_cache)
        ..sort((a, b) => b.totalDistanceKm.compareTo(a.totalDistanceKm));

  bool isDuplicate(String id) => _cache.any((c) => c.id == id);

  Future<void> add(FriendCard card) async {
    if (isDuplicate(card.id)) return;
    _cache.insert(0, card);
    await HiveBoxes.friendCards.put(card.id, card.toMap());
  }

  Future<void> remove(String id) async {
    _cache.removeWhere((c) => c.id == id);
    await HiveBoxes.friendCards.delete(id);
  }
}
