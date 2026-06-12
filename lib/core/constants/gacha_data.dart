import 'package:flutter/material.dart';
import '../../data/models/gacha_item.dart';

// Gacha pull rates
const double kGachaRateN = 0.60;
const double kGachaRateR = 0.30;
const double kGachaRateSR = 0.08;
const double kGachaRateSSR = 0.02;

// Gacha costs
const int kGachaCost1x = 300;
const int kGachaCost10x = 2500;

// All available gacha items
const List<Map<String, String>> kGachaItemDefs = [
  // Aura (オーラ)
  {'id': 'aura_n_basic', 'type': 'aura', 'rarity': 'N', 'name': 'ベーシックオーラ', 'description': 'シンプルな白い光のオーラ'},
  {'id': 'aura_r_flame', 'type': 'aura', 'rarity': 'R', 'name': 'フレイムオーラ', 'description': '炎をまとった赤いオーラ'},
  {'id': 'aura_r_ice', 'type': 'aura', 'rarity': 'R', 'name': 'アイスオーラ', 'description': '氷を纏った青いオーラ'},
  {'id': 'aura_r_wind', 'type': 'aura', 'rarity': 'R', 'name': 'ウィンドオーラ', 'description': '風をまとった緑のオーラ'},
  {'id': 'aura_sr_thunder', 'type': 'aura', 'rarity': 'SR', 'name': 'サンダーオーラ', 'description': '雷を纏った黄金のオーラ'},
  {'id': 'aura_sr_shadow', 'type': 'aura', 'rarity': 'SR', 'name': 'シャドウオーラ', 'description': '暗黒のオーラ。謎めいた紫の光'},
  {'id': 'aura_ssr_rainbow', 'type': 'aura', 'rarity': 'SSR', 'name': 'レインボーオーラ', 'description': '七色に輝く究極のオーラ'},

  // Banner (バナー)
  {'id': 'banner_n_beginner', 'type': 'banner', 'rarity': 'N', 'name': 'ビギナーバナー', 'description': '走り始めたばかりのランナーバナー'},
  {'id': 'banner_r_runner', 'type': 'banner', 'rarity': 'R', 'name': 'ランナーバナー', 'description': '本格的なランナーの証'},
  {'id': 'banner_r_champion', 'type': 'banner', 'rarity': 'R', 'name': 'チャンピオンバナー', 'description': '勝利を収めたランナーのバナー'},
  {'id': 'banner_sr_legend', 'type': 'banner', 'rarity': 'SR', 'name': 'レジェンドバナー', 'description': '伝説のランナーだけが持つバナー'},
  {'id': 'banner_ssr_god', 'type': 'banner', 'rarity': 'SSR', 'name': 'ゴッドバナー', 'description': '神のランナーに与えられる至高のバナー'},

  // Frame (フレーム)
  {'id': 'frame_n_simple', 'type': 'frame', 'rarity': 'N', 'name': 'シンプルフレーム', 'description': 'シンプルなカードフレーム'},
  {'id': 'frame_r_silver', 'type': 'frame', 'rarity': 'R', 'name': 'シルバーフレーム', 'description': '銀色に輝くカードフレーム'},
  {'id': 'frame_r_gold', 'type': 'frame', 'rarity': 'R', 'name': 'ゴールドフレーム', 'description': '金色に輝くカードフレーム'},
  {'id': 'frame_sr_diamond', 'type': 'frame', 'rarity': 'SR', 'name': 'ダイヤフレーム', 'description': 'ダイヤモンドのように輝くフレーム'},
  {'id': 'frame_ssr_cosmic', 'type': 'frame', 'rarity': 'SSR', 'name': 'コズミックフレーム', 'description': '宇宙の輝きを持つ究極フレーム'},

  // Skin (スキン)
  {'id': 'skin_n_basic', 'type': 'skin', 'rarity': 'N', 'name': 'ベーシックスキン', 'description': 'シンプルなモンスタースキン'},
  {'id': 'skin_r_gradient', 'type': 'skin', 'rarity': 'R', 'name': 'グラデスキン', 'description': 'グラデーションカラーのスキン'},
  {'id': 'skin_r_checker', 'type': 'skin', 'rarity': 'R', 'name': 'チェッカースキン', 'description': 'チェッカーパターンのスキン'},
  {'id': 'skin_sr_galaxy', 'type': 'skin', 'rarity': 'SR', 'name': 'ギャラクシースキン', 'description': '銀河のような幻想的なスキン'},
  {'id': 'skin_ssr_dragon', 'type': 'skin', 'rarity': 'SSR', 'name': 'ドラゴンスキン', 'description': '龍の鱗を纏った究極のスキン'},
];

GachaItem gachaItemFromDef(Map<String, String> def) => GachaItem(
      id: def['id']!,
      type: def['type']!,
      rarity: def['rarity']!,
      name: def['name']!,
      description: def['description']!,
      source: 'gacha',
    );

final List<Map<String, String>> kGachaPoolN =
    kGachaItemDefs.where((d) => d['rarity'] == 'N').toList();
final List<Map<String, String>> kGachaPoolR =
    kGachaItemDefs.where((d) => d['rarity'] == 'R').toList();
final List<Map<String, String>> kGachaPoolSR =
    kGachaItemDefs.where((d) => d['rarity'] == 'SR').toList();
final List<Map<String, String>> kGachaPoolSSR =
    kGachaItemDefs.where((d) => d['rarity'] == 'SSR').toList();

Color rarityColor(String rarity) {
  switch (rarity) {
    case 'SSR':
      return const Color(0xFFFFD700);
    case 'SR':
      return const Color(0xFFE040FB);
    case 'R':
      return const Color(0xFF42A5F5);
    default:
      return const Color(0xFF9E9E9E);
  }
}
