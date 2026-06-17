# 03 データモデル仕様

## ストレージ

**ローカル DB:** Hive 2.2.3（オフラインファースト）  
**ネットワーク同期:** なし（将来的な拡張ポイント）

---

## Hive ボックス一覧

| ボックス名 | モデル | 説明 |
|-----------|-------|-----|
| `users` | User | ユーザー情報（1件のみ） |
| `monsters` | Monster | モンスター情報（1件のみ） |
| `runRecords` | RunRecord | ランの記録（複数） |
| `gachaItems` | GachaItem | 所持アイテム一覧 |
| `achievements` | Achievement | 実績進捗 |
| `dailyMissions` | DailyMission | デイリーミッション |
| `friendCards` | FriendCard | 取り込んだフレンドカード |

**永続フラグ（個別 Hive エントリ）:**
- `onboarding_complete` — 初回起動済みかどうか
- `notifications` — 通知設定

---

## User モデル

| フィールド | 型 | デフォルト | 説明 |
|-----------|---|----------|-----|
| id | String | UUID | ユーザー一意 ID |
| username | String | 「ランナー」 | 表示名 |
| createdAt | DateTime | — | 作成日時 |
| totalDistanceKm | double | 0.0 | 全期間走行距離 |
| weeklyDistanceKm | double | 0.0 | 今週の走行距離 |
| currentCoins | int | 0 | 所持コイン |
| selectedTitle | String? | null | 装備中の称号 |
| selectedBanner | String? | null | 装備中のバナー |
| selectedFrame | String? | null | 装備中のフレーム |
| notificationEnabled | bool | true | 通知 ON/OFF |
| lastWeeklyResetDate | DateTime | — | 最後に週間リセットした月曜日 |
| resetCount | int | 0 | リセット回数（デバッグ用） |

**週間リセットロジック:**  
アプリ起動時に「今週の月曜日」を計算し、`lastWeeklyResetDate` と比較。異なれば `weeklyDistanceKm = 0` してリセット。

---

## Monster モデル

| フィールド | 型 | デフォルト | 説明 |
|-----------|---|----------|-----|
| id | String | UUID | モンスター一意 ID |
| name | String | — | モンスター名（ユーザー設定） |
| color | String | — | `'red'` / `'blue'` / `'green'` |
| level | int | 1 | 現在レベル（最大 50） |
| exp | int | 0 | 累積 EXP |
| currentEvolutionId | String | `'runmon'` | 現在の進化形態 ID |
| evolutionPath | List\<String\> | [] | 選択した進化履歴 |
| isEvolutionAvailable | bool | false | 進化選択可能フラグ |
| monsterNameChangeRemaining | int | 1 | モンスター名変更残り回数（0になると変更不可） |
| skinUnlocked | bool | false | Lv50 到達でスキン解放 |
| selectedSkin | String? | null | 装備中のスキン ID |
| selectedAura | String? | null | 装備中のオーラ ID |

---

## RunRecord モデル

| フィールド | 型 | 説明 |
|-----------|---|-----|
| id | String | UUID |
| startedAt | DateTime | ラン開始日時 |
| endedAt | DateTime | ラン終了日時 |
| distanceKm | double | 走行距離（km） |
| durationSeconds | int | 所要時間（秒） |
| averagePace | double | 平均ペース（分/km） |
| expGained | int | 獲得 EXP |
| coinsGained | int | 獲得コイン |
| appliedBonus | double | 適用された乗数（1.0〜1.5） |
| routePoints | List\<RoutePoint\> | GPS 座標列 |

### RunRecord のバリデーション条件

| 条件 | 閾値 |
|-----|-----|
| 最低距離 | 0.5 km |
| 最低時間 | 180 秒 |
| 異常速度除外 | > 25 km/h の区間を無効化 |

---

## RoutePoint モデル

| フィールド | 型 | 説明 |
|-----------|---|-----|
| latitude | double | 緯度 |
| longitude | double | 経度 |
| timestamp | DateTime | 記録時刻 |

---

## GachaItem モデル

| フィールド | 型 | 説明 |
|-----------|---|-----|
| id | String | アイテム ID |
| type | String | `'skin'` / `'aura'` / `'banner'` / `'frame'` |
| rarity | String | `'N'` / `'R'` / `'SR'` / `'SSR'` |
| name | String | アイテム名（日本語） |
| description | String | 説明文 |
| owned | bool | 所持フラグ |
| source | String | `'gacha'` / `'achievement'` / `'default'` |

### アイテム一覧（45種）

**オーラ（7種）:**

| ID | 名前 | レアリティ |
|----|-----|---------|
| aura_basic | ベーシック | N |
| aura_flame | フレイム | R |
| aura_ice | アイス | R |
| aura_wind | ウィンド | R |
| aura_thunder | サンダー | SR |
| aura_shadow | シャドウ | SR |
| aura_rainbow | レインボー | SSR |

**バナー（5種）:**

| ID | 名前 | レアリティ |
|----|-----|---------|
| banner_beginner | ビギナー | N |
| banner_runner | ランナー | R |
| banner_champion | チャンピオン | R |
| banner_legend | レジェンド | SR |
| banner_god | ゴッド | SSR |

**フレーム（5種）:**

| ID | 名前 | レアリティ |
|----|-----|---------|
| frame_simple | シンプル | N |
| frame_silver | シルバー | R |
| frame_gold | ゴールド | R |
| frame_diamond | ダイヤ | SR |
| frame_cosmic | コズミック | SSR |

**スキン（5種）:**

| ID | 名前 | レアリティ |
|----|-----|---------|
| skin_basic | ベーシック | N |
| skin_gradient | グラデ | R |
| skin_checker | チェッカー | R |
| skin_galaxy | ギャラクシー | SR |
| skin_dragon | ドラゴン | SSR |

---

## Achievement モデル

| フィールド | 型 | 説明 |
|-----------|---|-----|
| id | String | 実績 ID |
| category | String | `'distance'` / `'level'` / `'gacha'` / `'streak'` |
| title | String | 実績タイトル |
| description | String | 達成条件説明 |
| condition | Map\<String, dynamic\> | 条件定義（`type` + `threshold`） |
| rewardType | String | `'coins'` / `'title'` / `'aura'` / `'banner'` / `'frame'` / `'skin'` |
| rewardValue | dynamic | 報酬量または ID |
| isCompleted | bool | 達成フラグ |
| completedAt | DateTime? | 達成日時 |

---

## DailyMission モデル

| フィールド | 型 | 説明 |
|-----------|---|-----|
| id | String | ミッション ID |
| date | DateTime | 対象日 |
| title | String | ミッションタイトル |
| condition | Map\<String, dynamic\> | 達成条件 |
| rewardCoins | int | 報酬コイン数 |
| isCompleted | bool | 達成フラグ |

---

## FriendCard モデル（QR データ）

| フィールド | 型 | 説明 |
|-----------|---|-----|
| id | String | フレンド ID |
| username | String | フレンドのユーザー名 |
| monsterName | String | モンスター名 |
| monsterLevel | int | モンスターレベル |
| monsterImageId | String | 進化形態 ID |
| totalDistanceKm | double | 総走行距離 |
| weeklyDistanceKm | double | 今週の走行距離 |
| title | String? | 装備称号 |
| banner | String? | 装備バナー |
| frame | String? | 装備フレーム |
| aura | String? | 装備オーラ |
| qrData | String | JSON エンコードした全データ |
| importedAt | DateTime | 取り込み日時 |

---

## 進化ノード定義（EvolutionNode）

```
{
  id: String,                    // 'runmon', 'grandmon', ...
  name: String,                  // 日本語表示名
  emoji: String,                 // 絵文字（β版フォールバック表示用）
  requiredLevel: int,            // 解放に必要なレベル
  nextEvolutions: List<String>,  // 分岐先 ID（Lv10/20/30 は 2件、Lv40 は 0件）
  requiredParent: String?,       // 親進化 ID（ランモンは null）
  isFinalForm: bool,             // true = Lv40 最終形態（選択なし）
  description: String            // フレーバーテキスト
}
```

### 全ノードテーブル

| ID | 名前 | Lv | 親 | 次（2択） | 最終 |
|----|-----|---|---|--------|-----|
| runmon | ランモン | 1 | — | grandmon, wingmon | — |
| grandmon | グランドモン | 10 | runmon | beastmon, knightmon | — |
| wingmon | ウィングモン | 10 | runmon | birdmon, spirimon | — |
| beastmon | ビーストモン | 20 | grandmon | fenrirmon, leomon | — |
| knightmon | ナイトモン | 20 | grandmon | paladinmon, darkknightmon | — |
| birdmon | バードモン | 20 | wingmon | phenixmon, raichomon | — |
| spirimon | スピリモン | 20 | wingmon | luxmon, noxmon | — |
| fenrirmon | フェンリルモン | 30 | beastmon | fenrirlord | — |
| leomon | レオモン | 30 | beastmon | solreonlord | — |
| paladinmon | パラディンモン | 30 | knightmon | saintpaladin | — |
| darkknightmon | ダークナイトモン | 30 | knightmon | abyssknightlord | — |
| phenixmon | フェニモン | 30 | birdmon | phoenixlord | — |
| raichomon | ライチョウモン | 30 | birdmon | thunderbirdlord | — |
| luxmon | ルクスモン | 30 | spirimon | luminousseraph | — |
| noxmon | ノクスモン | 30 | spirimon | noxphantom | — |
| fenrirlord | フェンリルロード | 40 | fenrirmon | — | ✅ |
| solreonlord | ソルレオンロード | 40 | leomon | — | ✅ |
| saintpaladin | セイントパラディン | 40 | paladinmon | — | ✅ |
| abyssknightlord | アビスナイトロード | 40 | darkknightmon | — | ✅ |
| phoenixlord | フェニックスロード | 40 | phenixmon | — | ✅ |
| thunderbirdlord | サンダーバードロード | 40 | raichomon | — | ✅ |
| luminousseraph | ルミナスセラフ | 40 | luxmon | — | ✅ |
| noxphantom | ノクスファントム | 40 | noxmon | — | ✅ |

---

## シリアライゼーション

- **DateTime:** `millisecondsSinceEpoch`（int）として保存
- **再構築:** `DateTime.fromMillisecondsSinceEpoch(value)`
- **ネスト:** `RoutePoint[]` は `RunRecord` に JSON としてネスト保存
- **マップ形式:** `toMap()` / `fromMap()` パターンで全モデル統一
