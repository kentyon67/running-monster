import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../models/user.dart';

class UserRepository {
  static const _key = 'current_user';

  User? _cache;

  Future<User> loadOrCreate() async {
    final raw = HiveBoxes.user.get(_key);
    User user;
    if (raw == null) {
      user = User.initial(id: const Uuid().v4());
      await save(user);
    } else {
      try {
        user = User.fromMap(raw as Map);
      } catch (e) {
        debugPrint('UserRepository: corrupted user data — $e. Creating fresh user.');
        user = User.initial(id: const Uuid().v4());
        await save(user);
      }
    }
    _cache = user;
    final previousResetDate = user.lastWeeklyResetDate;
    _applyWeeklyReset(user);
    if (user.lastWeeklyResetDate != previousResetDate) {
      await save(user);
    }
    return _cache!;
  }

  User get current => _cache!;

  Future<void> save(User user) async {
    _cache = user;
    try {
      await HiveBoxes.user.put(_key, user.toMap());
    } catch (e) {
      debugPrint('UserRepository: failed to save user — $e');
    }
  }

  User _applyWeeklyReset(User user) {
    final now = DateTime.now();
    final thisMonday = _monday(now);
    if (thisMonday.isAfter(user.lastWeeklyResetDate)) {
      user.weeklyDistanceKm = 0.0;
      user.lastWeeklyResetDate = thisMonday;
    }
    return user;
  }

  DateTime _monday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }
}
