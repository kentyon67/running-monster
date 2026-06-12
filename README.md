# ランニングモンスター

GPSランニングでモンスターを育てるスマホアプリ。

## Phase 1 実装済み
- ボトムナビ（ホーム・ラン・モンスター・ガチャ・設定）
- ホーム画面（モンスター表示・EXPバー・統計）
- ラン画面（GPS計測・地図・リアルタイム表示）
- ラン結果（EXP/コイン加算・レベルアップ判定）
- ローカル保存（Hive）
- 週間距離の月曜リセット

## EXPカーブ
| レベル | 累計EXP | 累計距離 |
|---|---|---|
| Lv10 | 1,000 | 10km |
| Lv20 | 5,000 | 50km |
| Lv30 | 10,000 | 100km |
| Lv40 | 20,000 | 200km |
| Lv50 | 40,000 | 400km |

中間レベルは線形補間。

## セットアップ

```bash
flutter pub get
flutter run
```

## 技術スタック
- Flutter / Dart
- Riverpod (状態管理)
- go_router (ナビゲーション)
- Hive (ローカルDB)
- flutter_map + OpenStreetMap (地図)
- geolocator (GPS)
