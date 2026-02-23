# チュートリアルモード要件定義書

## 1. 概要

### 1.1 目的
Local Photo Contestプラットフォームの各ユーザーロール（参加者・運営者・管理者）に対して、初回利用時およびオンデマンドでインタラクティブなチュートリアルを提供し、ユーザーのオンボーディング体験を向上させる。

### 1.2 背景
- 新規ユーザーがプラットフォームの機能を理解するまでに時間がかかる
- 運営者向けの高度な機能（審査員招待、評価基準設定など）の利用率が低い
- ヘルプドキュメントだけでは直感的な操作習得が難しい

### 1.3 期待される効果
- ユーザーのオンボーディング時間の短縮
- 機能利用率の向上
- サポート問い合わせの削減
- ユーザー満足度の向上

---

## 2. 対象ユーザー

| ロール | 説明 | チュートリアル優先度 |
|--------|------|---------------------|
| participant | 写真投稿・投票を行う一般参加者 | 高 |
| organizer | コンテストを作成・運営する運営者 | 最高 |
| admin | システム全体を管理する管理者 | 中 |
| judge | 審査員として招待されたユーザー | 高 |

---

## 3. チュートリアルの種類

### 3.1 初回ログインチュートリアル
- **トリガー**: ユーザーが初めてログインした時
- **必須/任意**: 任意（スキップ可能）
- **表示形式**: フルスクリーンウェルカムモーダル → ステップバイステップガイド

### 3.2 機能別チュートリアル
- **トリガー**: 特定の機能ページに初めてアクセスした時
- **必須/任意**: 任意（スキップ可能）
- **表示形式**: ツールチップ・ハイライト形式

### 3.3 オンデマンドチュートリアル
- **トリガー**: ユーザーがヘルプボタンをクリックした時
- **必須/任意**: 任意
- **表示形式**: サイドパネルまたはモーダル

### 3.4 コンテキストヘルプ
- **トリガー**: 特定の入力フィールドやボタンにホバーした時
- **必須/任意**: 任意
- **表示形式**: ツールチップ

---

## 4. ロール別チュートリアル内容

### 4.1 参加者（Participant）チュートリアル

#### 4.1.1 初回ログインチュートリアル
**ステップ数**: 5ステップ

| ステップ | 内容 | 対象要素 |
|---------|------|----------|
| 1 | ウェルカムメッセージ・プラットフォーム紹介 | フルスクリーンモーダル |
| 2 | コンテスト一覧の見方 | コンテスト一覧ページ |
| 3 | 写真の投稿方法 | 投稿フォーム |
| 4 | 投票の仕方 | ギャラリーページ |
| 5 | マイページの使い方 | マイページナビゲーション |

#### 4.1.2 機能別チュートリアル

**写真投稿チュートリアル**
- 画像アップロードエリアのハイライト
- タイトル・説明文の入力ガイド
- 撮影スポットの選択方法
- 位置情報の登録方法

**投票チュートリアル**
- 作品の閲覧方法
- 投票ボタンの説明
- 投票制限（1作品1票など）の説明

**コメントチュートリアル**
- コメントの投稿方法
- コメントのマナー説明

---

### 4.2 運営者（Organizer）チュートリアル

#### 4.2.1 初回ログインチュートリアル
**ステップ数**: 8ステップ

| ステップ | 内容 | 対象要素 |
|---------|------|----------|
| 1 | 運営者ダッシュボードの概要 | ダッシュボード全体 |
| 2 | コンテスト作成の流れ | 新規作成ボタン |
| 3 | エリア・スポット管理の説明 | サイドナビゲーション |
| 4 | 審査員招待機能の紹介 | 審査員管理メニュー |
| 5 | 評価基準設定の説明 | 評価基準メニュー |
| 6 | モデレーション機能の紹介 | モデレーションメニュー |
| 7 | 統計・分析機能の説明 | 統計メニュー |
| 8 | 結果発表の流れ | 結果発表メニュー |

#### 4.2.2 機能別チュートリアル

**コンテスト作成チュートリアル**
1. 基本情報の入力（タイトル、説明、テーマ）
2. 期間設定（応募期間、審査期間、結果発表日）
3. カテゴリ選択
4. 応募条件の設定
5. 賞品設定
6. テンプレートからの作成方法

**エリア・スポット管理チュートリアル**
1. エリアの作成方法
2. スポットの追加方法
3. 地図上での位置指定
4. スポット情報の編集

**審査員管理チュートリアル**
1. 審査員の招待方法（メール送信）
2. 招待ステータスの確認
3. 審査員の権限説明
4. 評価基準の設定方法

**評価基準設定チュートリアル**
1. 評価基準の追加
2. 配点の設定
3. 基準の優先順位設定
4. ハイブリッドランキングの説明

**モデレーションチュートリアル**
1. 審査待ち作品の確認
2. 承認・却下の方法
3. AWS Rekognitionによる自動モデレーションの説明
4. モデレーション結果の確認

**統計ダッシュボードチュートリアル**
1. 応募数推移グラフの見方
2. エリア別応募分布の確認
3. 投票分析の活用方法
4. データエクスポート機能

**結果発表チュートリアル**
1. ランキングプレビューの確認
2. 結果の確定方法
3. 通知送信の設定
4. 結果ページの公開

---

### 4.3 管理者（Admin）チュートリアル

#### 4.3.1 初回ログインチュートリアル
**ステップ数**: 6ステップ

| ステップ | 内容 | 対象要素 |
|---------|------|----------|
| 1 | 管理者ダッシュボードの概要 | ダッシュボード全体 |
| 2 | ユーザー管理機能 | ユーザー一覧 |
| 3 | 全コンテスト管理 | コンテスト一覧 |
| 4 | カテゴリ管理 | カテゴリ設定 |
| 5 | 監査ログの確認方法 | 監査ログ画面 |
| 6 | システム設定 | 設定メニュー |

#### 4.3.2 機能別チュートリアル

**ユーザー管理チュートリアル**
1. ユーザー検索・フィルタリング
2. ロール変更方法
3. アカウントのロック/アンロック
4. ユーザー情報の編集

**監査ログチュートリアル**
1. ログの検索方法
2. フィルタリングオプション
3. ログの詳細確認
4. セキュリティイベントの識別

---

### 4.4 審査員（Judge）チュートリアル

#### 4.4.1 招待受諾後チュートリアル
**ステップ数**: 5ステップ

| ステップ | 内容 | 対象要素 |
|---------|------|----------|
| 1 | 審査員としての役割説明 | ウェルカムモーダル |
| 2 | 審査対象作品の確認方法 | 審査一覧ページ |
| 3 | 評価基準の確認 | 評価基準表示 |
| 4 | スコア入力方法 | 評価フォーム |
| 5 | コメント記入方法 | コメントエリア |

---

## 5. UI/UX要件

### 5.1 チュートリアルUIコンポーネント

#### 5.1.1 ウェルカムモーダル
```
+------------------------------------------+
|                                          |
|     [ロゴ]                               |
|                                          |
|     Local Photo Contestへようこそ！      |
|                                          |
|     [イラスト/アニメーション]            |
|                                          |
|     プラットフォームの使い方を           |
|     ご案内します                         |
|                                          |
|     [チュートリアルを開始]  [スキップ]   |
|                                          |
+------------------------------------------+
```

#### 5.1.2 ステップインジケーター
```
  ● ○ ○ ○ ○
  1/5 ステップ
```

#### 5.1.3 ハイライト＋ツールチップ
```
+------------------+
| 対象要素         | ← ハイライト（半透明オーバーレイ）
+------------------+
        ↓
+---------------------------+
| ここをクリックして        |
| コンテストを作成できます  |
|                           |
| [次へ]  [スキップ]        |
+---------------------------+
```

#### 5.1.4 サイドパネルヘルプ
```
+------------------+-------------------+
|                  | ヘルプ          × |
|   メイン画面     |                   |
|                  | □ コンテスト作成  |
|                  | □ エリア管理      |
|                  | □ 審査員招待      |
|                  |                   |
|                  | [動画を見る]      |
+------------------+-------------------+
```

### 5.2 デザインガイドライン

| 要素 | 仕様 |
|------|------|
| プライマリカラー | Indigo-600 (#4F46E5) |
| セカンダリカラー | Purple-600 (#9333EA) |
| オーバーレイ | rgba(0, 0, 0, 0.5) |
| ツールチップ背景 | White with shadow-lg |
| ボーダー半径 | rounded-lg (8px) |
| アニメーション | transition-all duration-300 |
| フォント | システムデフォルト（Tailwind） |

### 5.3 レスポンシブ対応

| 画面サイズ | 対応方針 |
|-----------|----------|
| デスクトップ (>1024px) | フル機能チュートリアル |
| タブレット (768-1024px) | 簡略化したチュートリアル |
| モバイル (<768px) | 最小限のステップ、縦スクロール形式 |

### 5.4 アクセシビリティ要件

- キーボードナビゲーション対応（Tab, Enter, Escape）
- スクリーンリーダー対応（ARIA属性）
- フォーカストラップ（モーダル内）
- 十分なカラーコントラスト比（WCAG 2.1 AA準拠）
- アニメーション停止オプション（prefers-reduced-motion対応）

---

## 6. 技術要件

### 6.1 データモデル

#### TutorialProgress（チュートリアル進捗）
```ruby
# db/migrate/XXXXXX_create_tutorial_progresses.rb

create_table :tutorial_progresses do |t|
  t.references :user, null: false, foreign_key: true
  t.string :tutorial_type, null: false  # 'onboarding', 'contest_creation', etc.
  t.string :current_step, default: nil  # 現在のステップID
  t.boolean :completed, default: false
  t.boolean :skipped, default: false
  t.datetime :started_at
  t.datetime :completed_at
  t.json :step_data, default: {}  # 各ステップの完了状態など
  t.timestamps
end

add_index :tutorial_progresses, [:user_id, :tutorial_type], unique: true
```

#### TutorialStep（チュートリアルステップ定義）
```ruby
# db/migrate/XXXXXX_create_tutorial_steps.rb

create_table :tutorial_steps do |t|
  t.string :tutorial_type, null: false
  t.string :step_id, null: false
  t.integer :order, null: false
  t.string :title, null: false
  t.text :description
  t.string :target_selector  # CSSセレクター
  t.string :target_path      # URLパス
  t.string :position, default: 'bottom'  # tooltip位置
  t.json :options, default: {}
  t.timestamps
end

add_index :tutorial_steps, [:tutorial_type, :step_id], unique: true
add_index :tutorial_steps, [:tutorial_type, :order]
```

### 6.2 モデル

```ruby
# app/models/tutorial_progress.rb
class TutorialProgress < ApplicationRecord
  belongs_to :user

  enum :tutorial_type, {
    participant_onboarding: 'participant_onboarding',
    organizer_onboarding: 'organizer_onboarding',
    admin_onboarding: 'admin_onboarding',
    judge_onboarding: 'judge_onboarding',
    contest_creation: 'contest_creation',
    area_management: 'area_management',
    judge_invitation: 'judge_invitation',
    moderation: 'moderation',
    statistics: 'statistics',
    photo_submission: 'photo_submission',
    voting: 'voting'
  }

  validates :tutorial_type, presence: true
  validates :user_id, uniqueness: { scope: :tutorial_type }

  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false, skipped: false) }
  scope :skipped, -> { where(skipped: true) }

  def complete!
    update!(completed: true, completed_at: Time.current)
  end

  def skip!
    update!(skipped: true, completed_at: Time.current)
  end

  def advance_to!(step_id)
    update!(current_step: step_id)
    step_data[step_id] = { completed_at: Time.current.iso8601 }
    save!
  end
end
```

### 6.3 コントローラー

```ruby
# app/controllers/tutorials_controller.rb
class TutorialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tutorial_progress, only: [:show, :update, :skip]

  # GET /tutorials/:tutorial_type
  def show
    @steps = TutorialStep.where(tutorial_type: params[:tutorial_type])
                         .order(:order)
    render json: {
      progress: @tutorial_progress,
      steps: @steps,
      current_step: current_step
    }
  end

  # POST /tutorials/:tutorial_type/start
  def start
    @tutorial_progress = current_user.tutorial_progresses
      .find_or_create_by(tutorial_type: params[:tutorial_type])
    @tutorial_progress.update!(started_at: Time.current) unless @tutorial_progress.started_at
    render json: { progress: @tutorial_progress }
  end

  # PATCH /tutorials/:tutorial_type
  def update
    @tutorial_progress.advance_to!(params[:step_id])

    if final_step?
      @tutorial_progress.complete!
    end

    render json: { progress: @tutorial_progress }
  end

  # POST /tutorials/:tutorial_type/skip
  def skip
    @tutorial_progress.skip!
    render json: { progress: @tutorial_progress }
  end

  # GET /tutorials/status
  def status
    progresses = current_user.tutorial_progresses.index_by(&:tutorial_type)
    render json: { progresses: progresses }
  end

  private

  def set_tutorial_progress
    @tutorial_progress = current_user.tutorial_progresses
      .find_or_initialize_by(tutorial_type: params[:tutorial_type])
  end

  def current_step
    TutorialStep.find_by(
      tutorial_type: params[:tutorial_type],
      step_id: @tutorial_progress.current_step
    )
  end

  def final_step?
    last_step = TutorialStep.where(tutorial_type: params[:tutorial_type])
                            .order(:order).last
    params[:step_id] == last_step&.step_id
  end
end
```

### 6.4 Stimulusコントローラー

```javascript
// app/javascript/controllers/tutorial_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "tooltip", "progress"]
  static values = {
    tutorialType: String,
    autoStart: { type: Boolean, default: false }
  }

  connect() {
    if (this.autoStartValue) {
      this.checkAndStart()
    }
  }

  async checkAndStart() {
    const response = await fetch('/tutorials/status')
    const { progresses } = await response.json()

    const progress = progresses[this.tutorialTypeValue]
    if (!progress || (!progress.completed && !progress.skipped)) {
      this.start()
    }
  }

  async start() {
    await fetch(`/tutorials/${this.tutorialTypeValue}/start`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    await this.loadTutorial()
  }

  async loadTutorial() {
    const response = await fetch(`/tutorials/${this.tutorialTypeValue}`)
    const { steps, current_step } = await response.json()

    this.steps = steps
    this.currentStepIndex = current_step
      ? steps.findIndex(s => s.step_id === current_step.step_id)
      : 0

    this.showStep(this.currentStepIndex)
  }

  showStep(index) {
    const step = this.steps[index]
    if (!step) {
      this.complete()
      return
    }

    // オーバーレイ表示
    this.showOverlay()

    // ターゲット要素をハイライト
    const target = document.querySelector(step.target_selector)
    if (target) {
      this.highlightElement(target)
      this.showTooltip(target, step)
    }

    // 進捗更新
    this.updateProgress(index)
  }

  highlightElement(element) {
    element.classList.add('tutorial-highlight')
    element.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }

  showTooltip(target, step) {
    const tooltip = this.tooltipTarget
    tooltip.innerHTML = `
      <div class="p-4">
        <h3 class="font-bold text-lg mb-2">${step.title}</h3>
        <p class="text-gray-600 mb-4">${step.description}</p>
        <div class="flex justify-between items-center">
          <span class="text-sm text-gray-500">
            ${this.currentStepIndex + 1}/${this.steps.length}
          </span>
          <div class="space-x-2">
            <button data-action="tutorial#skip"
                    class="px-3 py-1 text-gray-500 hover:text-gray-700">
              スキップ
            </button>
            <button data-action="tutorial#next"
                    class="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">
              ${this.currentStepIndex === this.steps.length - 1 ? '完了' : '次へ'}
            </button>
          </div>
        </div>
      </div>
    `
    tooltip.classList.remove('hidden')
    this.positionTooltip(tooltip, target, step.position)
  }

  positionTooltip(tooltip, target, position) {
    const rect = target.getBoundingClientRect()
    // 位置計算ロジック
  }

  async next() {
    const step = this.steps[this.currentStepIndex]

    await fetch(`/tutorials/${this.tutorialTypeValue}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ step_id: step.step_id })
    })

    this.clearHighlight()
    this.currentStepIndex++
    this.showStep(this.currentStepIndex)
  }

  async skip() {
    await fetch(`/tutorials/${this.tutorialTypeValue}/skip`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    this.cleanup()
  }

  complete() {
    this.cleanup()
    this.showCompletionMessage()
  }

  cleanup() {
    this.hideOverlay()
    this.clearHighlight()
    this.tooltipTarget.classList.add('hidden')
  }

  showOverlay() {
    this.overlayTarget.classList.remove('hidden')
  }

  hideOverlay() {
    this.overlayTarget.classList.add('hidden')
  }

  clearHighlight() {
    document.querySelectorAll('.tutorial-highlight').forEach(el => {
      el.classList.remove('tutorial-highlight')
    })
  }

  updateProgress(index) {
    if (this.hasProgressTarget) {
      const percentage = ((index + 1) / this.steps.length) * 100
      this.progressTarget.style.width = `${percentage}%`
    }
  }

  showCompletionMessage() {
    // 完了メッセージ表示
  }
}
```

### 6.5 ルーティング

```ruby
# config/routes.rb
resources :tutorials, param: :tutorial_type, only: [:show, :update] do
  member do
    post :start
    post :skip
  end
  collection do
    get :status
  end
end
```

### 6.6 CSS

```css
/* app/assets/stylesheets/tutorial.css */

.tutorial-overlay {
  @apply fixed inset-0 bg-black bg-opacity-50 z-40;
}

.tutorial-highlight {
  @apply relative z-50;
  box-shadow: 0 0 0 4px theme('colors.indigo.500'),
              0 0 0 8px rgba(79, 70, 229, 0.3);
  border-radius: 8px;
}

.tutorial-tooltip {
  @apply absolute z-50 bg-white rounded-lg shadow-2xl;
  @apply border border-gray-200;
  max-width: 360px;
  animation: fadeIn 0.3s ease-out;
}

.tutorial-tooltip::before {
  content: '';
  @apply absolute w-3 h-3 bg-white border-l border-t border-gray-200;
  transform: rotate(45deg);
}

.tutorial-tooltip[data-position="bottom"]::before {
  @apply -top-1.5 left-1/2 -translate-x-1/2;
}

.tutorial-tooltip[data-position="top"]::before {
  @apply -bottom-1.5 left-1/2 -translate-x-1/2;
  transform: rotate(225deg);
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.tutorial-progress-bar {
  @apply h-1 bg-indigo-600 rounded-full;
  transition: width 0.3s ease-out;
}
```

---

## 7. チュートリアル完了条件

### 7.1 完了条件

| チュートリアル種別 | 完了条件 |
|------------------|----------|
| 初回オンボーディング | 全ステップを閲覧 or スキップ |
| 機能別チュートリアル | 全ステップを閲覧 or 該当機能を実際に使用 |
| コンテキストヘルプ | 閲覧のみ（記録不要） |

### 7.2 スキップ機能

- 各ステップで「スキップ」ボタンを表示
- 全体スキップ時は確認ダイアログを表示
- スキップ後も設定画面から再開可能

### 7.3 リセット機能

- マイページ設定から個別チュートリアルをリセット可能
- リセット後、該当ページアクセス時に再度チュートリアル開始

---

## 8. ユーザー設定

### 8.1 設定項目

```ruby
# Userモデルに追加するカラム
add_column :users, :tutorial_settings, :json, default: {
  show_tutorials: true,
  show_context_help: true,
  reduced_motion: false
}
```

### 8.2 設定画面UI

```
チュートリアル設定
─────────────────────────────────────
☑ チュートリアルを表示する
☑ コンテキストヘルプを表示する
☐ アニメーションを減らす

チュートリアル進捗
─────────────────────────────────────
○ 初回ガイド         [完了] [リセット]
○ コンテスト作成      [未完了] [開始]
○ エリア管理         [スキップ済] [リセット]
```

---

## 9. 分析・計測

### 9.1 トラッキング項目

| イベント | データ |
|---------|--------|
| tutorial_started | tutorial_type, user_role |
| tutorial_step_viewed | tutorial_type, step_id, duration |
| tutorial_completed | tutorial_type, total_duration |
| tutorial_skipped | tutorial_type, skipped_at_step |
| help_button_clicked | page, context |

### 9.2 ダッシュボード指標

- チュートリアル完了率（ロール別）
- 平均完了時間
- スキップ率・スキップポイント
- 機能利用率との相関

---

## 10. 実装フェーズ

### Phase 1: 基盤構築
- データモデル作成
- 基本UIコンポーネント実装
- Stimulusコントローラー実装
- API実装

### Phase 2: 運営者チュートリアル
- 初回オンボーディング
- コンテスト作成チュートリアル
- エリア・スポット管理チュートリアル

### Phase 3: 参加者チュートリアル
- 初回オンボーディング
- 写真投稿チュートリアル
- 投票チュートリアル

### Phase 4: 審査員・管理者チュートリアル
- 審査員オンボーディング
- 管理者オンボーディング
- 高度な機能チュートリアル

### Phase 5: 拡張機能
- コンテキストヘルプ
- 動画チュートリアル統合
- 分析ダッシュボード

---

## 11. テスト要件

### 11.1 ユニットテスト
- TutorialProgress モデルテスト
- TutorialStep モデルテスト
- TutorialsController テスト

### 11.2 システムテスト
- チュートリアル開始・完了フロー
- スキップ機能
- リセット機能
- レスポンシブ表示

### 11.3 アクセシビリティテスト
- キーボードナビゲーション
- スクリーンリーダー動作確認

---

## 12. 将来の拡張

- インタラクティブデモモード（実際のデータを使わないサンドボックス）
- 動画チュートリアルの統合
- AIによるパーソナライズされたヘルプ
- 多言語対応
- ゲーミフィケーション（チュートリアル完了バッジ）

---

## 付録

### A. チュートリアルステップ定義（シードデータ）

```ruby
# db/seeds/tutorial_steps.rb

TutorialStep.create!([
  # 参加者オンボーディング
  {
    tutorial_type: 'participant_onboarding',
    step_id: 'welcome',
    order: 1,
    title: 'Local Photo Contestへようこそ！',
    description: '地域の魅力を写真で発信するプラットフォームです。このチュートリアルでは、基本的な使い方をご案内します。',
    target_selector: nil,
    position: 'center'
  },
  {
    tutorial_type: 'participant_onboarding',
    step_id: 'contests_list',
    order: 2,
    title: 'コンテスト一覧',
    description: 'ここから開催中のコンテストを確認できます。興味のあるコンテストをクリックして詳細を見てみましょう。',
    target_selector: '[data-tutorial="contests-list"]',
    target_path: '/contests',
    position: 'bottom'
  },
  # ... 他のステップ
])
```

### B. 用語集

| 用語 | 説明 |
|------|------|
| オンボーディング | 初回利用時のガイダンス |
| ツールチップ | UI要素の説明を表示する小さなポップアップ |
| ハイライト | 注目すべき要素を視覚的に強調すること |
| コンテキストヘルプ | 現在の操作に関連するヘルプ情報 |
