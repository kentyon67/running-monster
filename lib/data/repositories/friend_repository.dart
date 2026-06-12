import 'package:flutter/foundation.dart';
import '../local/hive_boxes.dart';
import '../models/friend_card.dart';

class FriendRepository {
  List<FriendCard> _cache = [];

  Future<void> load() async {
    final box = HiveBoxes.friendCards;
    final cards = <FriendCard>[];
    for (final k in box.keys) {
      try {
        final raw = box.get(k);
        if (raw == null) continue;
        cards.add(FriendCard.fromMap(raw as Map));
      } catch (e) {
        debugPrint('FriendRepository: corrupted entry $k — $e');
      }
    }
    cards.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    _cache = cards;
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
    try {
      await HiveBoxes.friendCards.put(card.id, card.toMap());
    } catch (e) {
      debugPrint('FriendRepository: failed to add friend ${card.id} — $e');
    }
  }

  Future<void> remove(String id) async {
    _cache.removeWhere((c) => c.id == id);
    try {
      await HiveBoxes.friendCards.delete(id);
    } catch (e) {
      debugPrint('FriendRepository: failed to remove friend $id — $e');
    }
  }
}
