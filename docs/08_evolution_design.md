# 08 進化デザイン仕様

## 概要

進化システムはゲームの長期エンゲージメントの中核。4つの分岐点でプレイヤーが選択を行い、ユニークな育成ストーリーを作る。

---

## 進化ツリー全体図

```
                    Runmon (Lv1)
                   ⚡ カラー3種
                        |
              ┌─────────┴─────────┐
           Lv10                 Lv10
         Beastmon             Spiritmon
          🦁 獣道              👻 霊道
         /      \             /      \
      Lv20     Lv20        Lv20     Lv20
    Lionmon  Wolfmon    Phoenixmon Dragonmon
     🦁 王者   🐺 野生    🦅 再生    🐉 嵐
    /    \   /    \     /    \    /    \
  Lv30  Lv30Lv30  Lv30 Lv30  Lv30Lv30  Lv30
 Leomon King Fenrir Arctic Blaze Shadow Storm Crystal
  👑    🏆   ❄️    ❄️    🔥    🌑    ⚡    💎
```

**合計:** 1 基本形 + 2 Lv10 + 4 Lv20 + 8 Lv30/40 terminal = **15 形態**  
**カラー込み:** 15 形態 × 3 カラー = **45 パターン**

---

## 進化形態詳細

### 基本形（Lv1）

| ID | 名前 | 絵文字 | 解放レベル | 次の進化 |
|----|-----|-------|---------|--------|
| runmon | ランモン | ⚡ | 1 | beastmon, spiritmon |

### 第1進化（Lv10）

| ID | 名前 | 絵文字 | 解放レベル | 次の進化 |
|----|-----|-------|---------|--------|
| beastmon | ビーストモン | 🦁 | 10 | lionmon, wolfmon |
| spiritmon | スピリットモン | 👻 | 10 | phoenixmon, dragonmon |

### 第2進化（Lv20）

| ID | 名前 | 絵文字 | 親 | 次の進化 |
|----|-----|-------|---|--------|
| lionmon | ライオンモン | 🦁 | beastmon | leomon, kingmon |
| wolfmon | ウルフモン | 🐺 | beastmon | fenrirmon, arcticmon |
| phoenixmon | フェニックスモン | 🦅 | spiritmon | blazemon, shadowmon |
| dragonmon | ドラゴンモン | 🐉 | spiritmon | stormmon, crystalmon |

### 最終形態（Lv30/40 terminal）

| ID | 名前 | 絵文字 | 親 |
|----|-----|-------|---|
| leomon | レオモン | 👑 | lionmon |
| kingmon | キングモン | 🏆 | lionmon |
| fenrirmon | フェンリルモン | ❄️ | wolfmon |
| arcticmon | アークティックモン | ❄️ | wolfmon |
| blazemon | ブレイズモン | 🔥 | phoenixmon |
| shadowmon | シャドウモン | 🌑 | phoenixmon |
| stormmon | ストームモン | ⚡ | dragonmon |
| crystalmon | クリスタルモン | 💎 | dragonmon |

---

## 進化ロジック

### 解放条件

```
monster.level >= evolutionNode.requiredLevel
&& evolutionNode.requiredParent == monster.currentEvolutionId
```

条件を満たした時点で `isEvolutionAvailable = true` に設定。

### 選択フロー

1. ホーム画面に進化バナー（シマーアニメーション）表示
2. モンスター画面「進化」タブに選択肢表示
3. ユーザーが 2 択の 1 つをタップ → 確認ダイアログ（不可逆の警告）
4. 確認後:
   - `monster.evolutionPath.add(chosenId)`
   - `monster.currentEvolutionId = chosenId`
   - `monster.isEvolutionAvailable = false`
5. Hive へ保存 → ホーム画面でモンスター表示を更新

### 不可逆性

- 選択した進化は**変更・リセット不可**
- 進化履歴は `evolutionPath[]` に永続保存
- 課金やアイテムによるリセットも設計上なし（意図的）

---

## 進化のステータスへの影響

**なし。**

| 要素 | 影響 |
|-----|-----|
| HP/攻撃等のステータス | 存在しない |
| 報酬乗数 | 変化しない |
| ガチャ排出率 | 変化しない |
| ミッション内容 | 変化しない |

進化はあくまでも「プレイヤーのモンスターへの愛着と物語」を生むための仕組みであり、ゲームプレイ上の有利不利は存在しない。

---

## 進化とカラーの関係

- カラー（赤/青/緑）は初期選択時に固定
- 進化しても同カラーを維持
- 見た目のみの差異

---

## スキンシステム（進化外のカスタマイズ）

| 要素 | 仕様 |
|-----|-----|
| 解放条件 | Lv50 到達（`skinUnlocked = true`） |
| 取得方法 | ガチャのみ（N〜SSR） |
| 装備 | モンスター画面「アイテム」タブで選択 |
| 枚数 | 同時装備 1 枚 |
| 進化形態への影響 | なし（スキン ≠ 進化） |

スキンは「Lv50 到達後も走る理由」として機能するエンドゲームコンテンツ。

---

## 進化体験の設計意図

| ポイント | 意図 |
|--------|-----|
| 2択の分岐 | 「どちらも良さそう」な選択肢で迷わせる |
| 不可逆性 | 選んだことへの「責任感」と愛着 |
| 4回の選択機会 | 1.5年以上のプレイスパンで計4回のイベント |
| ステータス差なし | 後悔しない設計（選択の後悔をなくす） |
| カラー × 進化 | 「自分だけの」モンスター感 |
