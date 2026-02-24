# チュートリアル修正計画

## 問題の概要

チュートリアル実行時に以下の問題が発生:
1. オーバーレイで画面全体が暗くなり、操作対象が見えない
2. ハイライトすべき要素が表示されない
3. ユーザーが何を操作すべきかわからない

## 原因分析

### 原因1: ターゲットセレクターの不一致

シードデータのターゲットセレクターが、実際のビューに存在しない:

| ステップ | シードのセレクター | 実際のビュー |
|---------|-------------------|-------------|
| create_button | `[data-tutorial="create-contest"]` | **存在しない** |
| template | `[data-tutorial="contest-templates"]` | **存在しない** |
| publish | `[data-tutorial="publish-button"]` | **存在しない** |

ダッシュボードの「新規コンテスト作成」リンクには `data-tutorial` 属性がない。

### 原因2: ターゲット未発見時の挙動

`tutorial_controller.js` でターゲットが見つからない場合:
```javascript
if (target) {
  this.highlightElement(target)  // ← 実行されない
  this.showTooltip(target, step)
} else {
  this.showCenteredTooltip(step)  // ← 中央にツールチップのみ表示
}
```

オーバーレイは表示されるが、ハイライト要素がないため全画面が暗くなる。

### 原因3: ウェルカムモーダルとチュートリアルの競合

ウェルカムモーダル自体が tutorial controller を持っており、モーダル内のオーバーレイとチュートリアルのオーバーレイが混在している可能性がある。

---

## 修正計画

### Phase 1: ビューにdata-tutorial属性を追加

**対象ファイル:** `app/views/organizers/dashboard/show.html.erb`

```erb
<!-- 修正前 -->
<%= link_to new_organizers_contest_path, class: "..." do %>

<!-- 修正後 -->
<%= link_to new_organizers_contest_path, class: "...", data: { tutorial: "create-contest" } do %>
```

### Phase 2: シードデータの修正

**対象ファイル:** `db/seeds/tutorial_steps_v2.rb`

運営者オンボーディングのステップを、ダッシュボードで完結するように再設計:

```ruby
# 修正案: ダッシュボード内で完結する3ステップ
[
  {
    step_id: "welcome",
    position: 1,
    title: "ダッシュボード",
    description: "ここが運営の拠点です",
    target_selector: nil,  # 中央表示
    tooltip_position: "center",
    action_type: "observe"
  },
  {
    step_id: "create_contest",
    position: 2,
    title: "コンテスト作成",
    description: "ここから作成できます",
    target_selector: '[data-tutorial="create-contest"]',
    tooltip_position: "bottom",
    action_type: "tap"
  },
  {
    step_id: "stats",
    position: 3,
    title: "統計情報",
    description: "ここで状況を確認",
    target_selector: '[data-tutorial="stats-grid"]',
    tooltip_position: "bottom",
    action_type: "observe"
  }
]
```

### Phase 3: ターゲット未発見時のフォールバック改善

**対象ファイル:** `app/javascript/controllers/tutorial_controller.js`

```javascript
showStep(index) {
  const step = this.steps[index]
  if (!step) {
    this.complete()
    return
  }

  this.currentStepIndex = index
  this.stepStartTime = Date.now()
  this.updateProgress(index)

  if (step.target_selector) {
    const target = document.querySelector(step.target_selector)
    if (target) {
      this.showOverlay()  // ターゲットがある時のみオーバーレイ表示
      this.highlightElement(target)
      this.showTooltip(target, step)
    } else {
      // ターゲットが見つからない場合はオーバーレイなしで中央表示
      this.hideOverlay()
      this.showCenteredTooltip(step)
      console.warn(`Tutorial target not found: ${step.target_selector}`)
    }
  } else {
    // ターゲットセレクターがない場合（ウェルカム等）
    this.hideOverlay()
    this.showCenteredTooltip(step)
  }
}
```

### Phase 4: ウェルカムモーダルの分離

**対象ファイル:** `app/views/tutorials/_welcome_modal.html.erb`

ウェルカムモーダルを独立したコントローラーに分離し、チュートリアルとの競合を防ぐ:

```erb
<div id="welcome-modal"
     data-controller="welcome-modal"
     data-welcome-modal-tutorial-type-value="<%= current_user.onboarding_tutorial_type %>">
  <!-- モーダル内容 -->
  <button data-action="welcome-modal#startTutorial">チュートリアルを開始</button>
  <button data-action="welcome-modal#skip">スキップ</button>
</div>
```

新規 `welcome_modal_controller.js`:
```javascript
export default class extends Controller {
  static values = { tutorialType: String }

  startTutorial() {
    this.closeModal()
    // メインのチュートリアルコントローラーを起動
    const tutorialContainer = document.querySelector('[data-controller="tutorial"]')
    if (tutorialContainer) {
      tutorialContainer.tutorial.start()
    }
  }

  skip() {
    this.closeModal()
    // スキップAPIを呼び出し
  }

  closeModal() {
    this.element.remove()
  }
}
```

---

## 修正ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `app/views/organizers/dashboard/show.html.erb` | data-tutorial属性を追加 |
| `db/seeds/tutorial_steps_v2.rb` | セレクターを実際のビューに合わせて修正 |
| `app/javascript/controllers/tutorial_controller.js` | ターゲット未発見時のフォールバック改善 |
| `app/javascript/controllers/welcome_modal_controller.js` | 新規作成 |
| `app/views/tutorials/_welcome_modal.html.erb` | コントローラーを分離 |

---

## 実装順序

1. **Phase 3** (JavaScript修正) - ターゲット未発見時の即座の改善
2. **Phase 1** (ビュー修正) - data-tutorial属性の追加
3. **Phase 2** (シードデータ修正) - セレクターの整合性確保
4. **Phase 4** (モーダル分離) - 構造的な改善

---

## テスト項目

- [ ] オーバーレイ表示時にターゲット要素が見える
- [ ] ターゲット要素をクリックできる
- [ ] ターゲット未発見時はオーバーレイなしでツールチップが表示される
- [ ] ウェルカムモーダルから「開始」でチュートリアルが正常に起動
- [ ] 「スキップ」でチュートリアルがスキップされる
- [ ] 全ステップ完了後に完了トーストが表示される
