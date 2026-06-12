import 'dart:math';
import '../../data/models/gacha_item.dart';
import '../constants/gacha_data.dart';

class GachaEngine {
  static final _rng = Random();

  static GachaItem pull() {
    final roll = _rng.nextDouble();
    List<Map<String, String>> pool;
    if (roll < kGachaRateSSR) {
      pool = kGachaPoolSSR;
    } else if (roll < kGachaRateSSR + kGachaRateSR) {
      pool = kGachaPoolSR;
    } else if (roll < kGachaRateSSR + kGachaRateSR + kGachaRateR) {
      pool = kGachaPoolR;
    } else {
      pool = kGachaPoolN;
    }
    if (pool.isEmpty) pool = kGachaPoolN;
    final def = pool[_rng.nextInt(pool.length)];
    return gachaItemFromDef(def);
  }

  static List<GachaItem> pull10() => List.generate(10, (_) => pull());
}
