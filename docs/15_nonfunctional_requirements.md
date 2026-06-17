# 15 非機能要件チェックリスト

> 正式リリース品質の定量基準。測定方法と閾値を明記する。

---

## 1. パフォーマンス

### 起動・レスポンス

| 要件 | 目標値 | 測定方法 | 状態 |
|-----|-------|--------|-----|
| コールドスタート時間 | **2 秒以内** | Snapdragon 625 クラス実機（2018年製 Android 中堅機）での計測 | ☐ |
| ホーム画面初期描画 | 1 秒以内 | `flutter run --profile` + DevTools timeline | ☐ |
| ガチャ結果表示 | 1.5 秒以内（ネットワーク除く） | UI スレッド計測 | ☐ |
| Hive monster box 読み込み | 100ms 以内 | 最低スペック端末（Android 5.0, 1GB RAM） | ☐ |

**改善策:**
- Hive のコールドスタートを分割: `users` box のみ main.dart で開く、他は lazy-open
- AdMob 初期化を `WidgetsBinding.instance.addPostFrameCallback` でファーストフレーム後に移動
- `precacheImage()` は現在の進化形態 1 件のみ、起動時に全形態キャッシュ禁止

---

### フレームレート

| 要件 | 目標値 | 測定対象 | 状態 |
|-----|-------|--------|-----|
| ホーム画面 monster アニメーション | **60fps** | 呼吸ループ・ジャンプ演出 | ☐ |
| ラン計測中マップ描画 | 30fps 以上 | flutter_map + GPS ポリライン更新 | ☐ |
| SSR ガチャ演出パーティクル | 60fps（パーティクル上限 60個） | Snapdragon 450 クラスで検証 | ☐ |

---

### バッテリー

| 要件 | 目標値 | 測定方法 | 状態 |
|-----|-------|--------|-----|
| 30 分ランバッテリー消費 | **5% 以内**（3,000mAh 端末） | Android Battery Historian / iOS Instruments | ☐ |
| GPS ポーリング間隔 | 3〜5 秒（デフォルト最高速度ではなく指定） | `geolocator` `LocationSettings.distanceFilter` 設定 | ☐ |
| wakelock リリース | ラン終了時（クラッシュ・権限エラー含む）に必ず解放 | finally ブロック確認 | ☐ |

---

### アセット・容量

| 要件 | 目標値 | 測定方法 | 状態 |
|-----|-------|--------|-----|
| APK ダウンロードサイズ | **50MB 以内** | Google Play Console でのサイズ確認 | ☐ |
| インストール済みサイズ | 100MB 以内 | — | ☐ |
| 単一 PNG メモリ使用量 | `ResizeImage` でデコードサイズ制限 | `Image.asset(cacheWidth: 360)` 設定 | ☐ |
| flutter_map タイルキャッシュ上限 | 設定（長距離ランで 50MB 超防止） | — | ☐ |

**アセット軽量化:**
- Android 向け PNG → WebP lossless 変換（約 25% 削減）
- iOS は PNG 維持（WebP デコードの互換性問題回避）
- 全アセット 3x のみ納品（Flutter が自動ダウンスケール）

---

## 2. 信頼性・クラッシュ安全性

| 要件 | 目標値 | 状態 |
|-----|-------|-----|
| クラッシュフリー率 | **99%+**（Firebase Crashlytics 計測） | ☐ |
| D1 クラッシュ率 | 1% 以下 | ☐ |
| Hive box 破損時の graceful recovery | try/catch + box 再生成フォールバック | ☐ |
| モンスター PNG 未収録時のフォールバック | `Image.asset()` の `errorBuilder` → CustomPainter | ☐ |
| GPS 権限 deniedForever 時の UI | Settings 誘導ダイアログ（ラン開始不能の旨を明示） | ☐ |
| ラン途中クラッシュ時のデータ保護 | Hive への定期 flush 実装（進行データ保護） | ☐ |

---

## 3. GPS・距離計算精度

| 要件 | 目標値 | 状態 |
|-----|-------|-----|
| GPS 低精度フィルタ | accuracy > 30m のポイントを距離計算から除外 | ☐ |
| 異常速度フィルタ | > 25 km/h の区間を除外（仕様確定済み） | ☐ |
| タイムゾーン対応 | `timezone` パッケージ使用。EXP ボーナス時間帯判定 | ☐ |
| `lastRunDate` タイムゾーン | `DateTime.now()` はシステム TZ 依存 → UTC 保存を推奨 | ☐ |

---

## 4. メモリ管理

| 要件 | 対策 | 状態 |
|-----|-----|-----|
| AnimationController リーク | `dispose()` で全 controller を破棄 | ☐ |
| MapController リーク | flutter_map 7.x の MapController を dispose | ☐ |
| モンスター PNG メモリ | `cacheWidth` / `cacheHeight` を `Image.asset()` に設定 | ☐ |
| TickerProvider リーク | 感情アニメーションの `repeat()` は画面離脱時に停止 | ☐ |

---

## 5. アクセシビリティ

| 要件 | 基準 | 状態 |
|-----|-----|-----|
| テキストコントラスト | WCAG AA 準拠（4.5:1 以上） | ☐ |
| アイコンのみボタン | `Tooltip` + semantic label 必須（TalkBack / VoiceOver 対応） | ☐ |
| ボトムナビゲーションタップ領域 | 44pt 以上（iPhone SE 375pt 幅で確認） | ☐ |
| 感情ステートのテキスト表現 | アイコンだけでなく文字でも状態を伝える | ☐ |

**注意:** ラベンダー背景 × サンフラワーゴールドの組み合わせはコントラスト不足のリスクあり。必ずツールで計測する。

---

## 6. セキュリティ・プライバシー

| 要件 | 対策 | 状態 |
|-----|-----|-----|
| AdMob ID のハードコード禁止 | 環境設定ファイル or `--dart-define` で管理 | ☐ |
| IAP レシート | サーバー検証またはクライアントサイド `acknowledgePurchase` パターン実装 | ☐ |
| GPS データのサーバー送信なし | Hive ローカルのみであることをプライバシーポリシーに明記 | ☐ |
| 個人情報の収集なし | ユーザー名・モンスター名はローカルのみ保持 | ☐ |
| オープンソースライセンス準拠 | OpenStreetMap (ODbL)・依存パッケージのライセンス確認 | ☐ |

---

## 7. データ整合性

| 要件 | 対策 | 状態 |
|-----|-----|-----|
| Hive スキーマバージョン管理 | `typeId` を変更した際の migration 手順を用意 | ☐ |
| 大量ランレコード対策 | RunRecord は最新 90 日をデフォルト表示、全件は遅延ロード | ☐ |
| midnight daily mission リセット | `timezone` パッケージで端末 TZ を考慮した境界計算 | ☐ |
| ガチャ RNG | `Random()` は商業ゲームとして問題なし（ただし Android OEM RNG に注意） | ☐ |

---

## 8. 監視・アラート体制

| KPI | アラート閾値 | 通知先 |
|-----|-----------|------|
| クラッシュフリー率 | < 99% | Firebase Crashlytics → Email |
| D7 継続率 | < 20% | Firebase Analytics ダッシュボード |
| AdMob RPM 急落 | 前週比 -50% 以上 | AdMob → Email |
| ストア評価 | 4.0 以下 | 手動監視 |

> アラートの設定方法は docs/13 KPI メトリクスを参照。

---

## 測定ツール一覧

| ツール | 用途 |
|-------|-----|
| Flutter DevTools (Profile mode) | フレームレート・メモリ・起動時間 |
| Android Battery Historian | バッテリー消費分析 |
| iOS Instruments (Energy Log) | iOS バッテリー消費 |
| Firebase Crashlytics | クラッシュ監視・クラッシュフリー率 |
| Firebase Analytics | ユーザー行動・ファネル分析 |
| Google Play Console | APK サイズ・Android Vitals |
| App Store Connect | クラッシュレポート・評価動向 |
| Color Contrast Analyzer | WCAG コントラスト測定 |
