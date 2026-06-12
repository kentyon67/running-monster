import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../models/user.dart';

class UserRepository {
  static const _key = 'current_user';

  User? _cache;

  /// Load (or create) the user. Also handles weekly distance reset.
  Future<User> loadOrCreate() async {
    final raw = HiveBoxes.user.get(_key);
    User user;
    if (raw == null) {
      user = User.initial(id: const Uuid().v4());
      await save(user);
    } else {
      user = User.fromMap(raw as Map);
    }
    _cache = _applyWeeklyReset(user);
    if (_cache != user) await save(_cache!);
    return _cache!;
  }

  User get current => _cache!;

  Future<void> save(User user) async {
    _cache = user;
    await HiveBoxes.user.put(_key, user.toMap());
  }

  /// Reset weeklyDistanceKm if current Monday is after lastWeeklyResetDate.
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
