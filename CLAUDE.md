# CLAUDE.md — Running Monster

## プロジェクト概要

**Running Monster** は Flutter 製のフィットネス × モンスター育成アプリ。  
GPS でランニングを計測し、走った距離がそのままモンスターの成長に反映される。

- **パッケージ名:** `com.kentyon67.running_monster`
- **Flutter バージョン:** 3.4.0+（Dart SDK 3.4+）
- **対象プラットフォーム:** Android（メイン）・iOS

---

## ドキュメント一覧

仕様・設計の詳細は `docs/` を参照:

| ファイル | 内容 |
|--------|-----|
| [docs/01_game_design.md](docs/01_game_design.md) | コアループ・報酬計算・レベルシステム |
| [docs/02_screen_spec.md](docs/02_screen_spec.md) | 全画面仕様・ナビゲーション構造 |
| [docs/03_data_model.md](docs/03_data_model.md) | Hive モデル定義・フィールド一覧 |
| [docs/04_feature_spec.md](docs/04_feature_spec.md) | 機能ごとの詳細仕様 |
| [docs/05_ui_guidelines.md](docs/05_ui_guidelines.md) | カラー・タイポグラフィ・コンポーネント |
| [docs/06_art_direction.md](docs/06_art_direction.md) | ビジュアル方針・モンスターデザイン |
| [docs/07_monetization.md](docs/07_monetization.md) | ガチャ・広告・IAP 設計 |
| [docs/08_evolution_design.md](docs/08_evolution_design.md) | 進化ツリー・選択ロジック |
| [docs/09_product_vision.md](docs/09_product_vision.md) | ミッション・KPI・競合比較 |
| [docs/10_roadmap.md](docs/10_roadmap.md) | フェーズ別タスク・Known Issues |

---

## 技術スタック

| 用途 | ライブラリ |
|-----|---------|
| 状態管理 | flutter_riverpod 2.5.1 |
| ナビゲーション | go_router 14.6.1 |
| ローカル DB | hive 2.2.3 + hive_flutter |
| GPS 計測 | geolocator 13.0.2 |
| 地図表示 | flutter_map 7.0.2（OpenStreetMap） |
| 通知 | flutter_local_notifications 17.2.4 |
| 広告 | google_mobile_ads 9.0.0 |
| QR 生成 | qr_flutter 4.1.0 |
| QR スキャン | mobile_scanner 4.0.1 |
| 画像共有 | share_plus 10.1.4 / gal 2.3.0 |
| ウェイクロック | wakelock_plus 1.2.8 |

---

## ディレクトリ構成

```
lib/
├── core/
│   ├── constants/      # EXP・ガチャ・ミッション・進化・カラー・実績の定数
│   ├── design/         # app_theme（Material 3 テーマ定義）
│   ├── router/         # app_router（GoRouter 設定）
│   ├── utils/          # 計算ロジック（exp, level, gacha, streak, validator, asset_resolver）
│   └── widgets/        # 共通ウィジェット（premium_card, glow_button）
├── data/
│   ├── local/          # hive_boxes（ボックス名定数）
│   ├── models/         # User, Monster, RunRecord, GachaItem, Achievement, DailyMission, FriendCard
│   └── repositories/   # 各モデルのリポジトリ + Riverpod providers
├── features/
│   ├── home/           # ホーム画面（notifier + widgets）
│   ├── run/            # ラン計測・結果画面
│   ├── monster/        # モンスター詳細（3タブ）
│   ├── gacha/          # ガチャ画面
│   ├── missions/       # ミッション・実績
│   ├── settings/       # 設定・プライバシーポリシー
│   ├── profile/        # プロフィールカード QR 生成
│   ├── friends/        # フレンド QR スキャン
│   └── onboarding/     # 初回フロー
├── services/           # AdService, NotificationService, HapticService
├── shared/             # MainScaffold（ボトムナビ）
├── main.dart           # 初期化（Hive, Riverpod, 通知, 広告）
└── app.dart            # MaterialApp.router
```

---

## 主要なゲームパラメータ

| パラメータ | 値 |
|----------|---|
| 最大レベル | 50（ソフトキャップ） |
| 基本 EXP | 100/km |
| 基本コイン | 100/km |
| 最大 EXP 倍率 | 1.5×（10km 以上） |
| ガチャ 1 連コスト | 300 コイン |
| ガチャ 10 連コスト | 2,500 コイン |
| 週間目標 | 30km |
| 最低走行距離 | 0.5km |
| 最低走行時間 | 3 分（180 秒） |
| 進化分岐点 | Lv10 / Lv20 / Lv30 / Lv40 |

---

## 開発コマンド

```bash
# パッケージ取得
flutter pub get

# 開発実行
flutter run

# ビルド（Android APK）
flutter build apk --release

# ビルド（Android App Bundle）
flutter build appbundle --release

# テスト
flutter test

# アイコン生成
dart run flutter_launcher_icons

# スプラッシュ生成
dart run flutter_native_splash:create
```

---

## コーディング規則

- **状態管理:** AsyncNotifier / Notifier（Riverpod）を使用。`setState` は使わない
- **ナビゲーション:** `context.go()` / `context.push()`（GoRouter）
- **データ保存:** 必ず対応するリポジトリ経由で操作する
- **日時:** `DateTime.now()` は直接呼ばず、必要ならテスト可能な形で注入
- **コメント:** 「なぜ」が非自明な場合のみ。「何をするか」のコメントは書かない
- **命名:** Dart 標準に従う（lowerCamelCase）

---

## 重要な設計判断

| 決定 | 理由 |
|-----|-----|
| オフラインファースト（Hive のみ） | GPS 計測中のネットワーク依存を排除 |
| OpenStreetMap（API キー不要） | 費用・設定コストなしで地図を提供 |
| 進化は不可逆 | プレイヤーの選択への責任感と愛着を生む |
| コスメのみ課金 | ゲームプレイの公平性を絶対に守る |
| Material 3 | Flutter 最新標準に従い将来の互換性を確保 |

---

## リリース前必須対応

- [ ] `assets/monsters/` に実画像アセットを配置
- [ ] AdMob 本番広告ユニット ID を差し替え（`lib/services/ad_service.dart`）
- [ ] プライバシーポリシー URL を確定
- [ ] Firebase Crashlytics 等のクラッシュ監視を導入
- [ ] Android・iOS の権限説明文を各ストア向けに整備
