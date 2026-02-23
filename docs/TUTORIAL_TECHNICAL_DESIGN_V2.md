# チュートリアルシステム技術設計書 v2.0
## 桜井政博氏の設計哲学に基づく実装設計

---

## 1. システム概要

### 1.1 アーキテクチャ概要

```
┌─────────────────────────────────────────────────────────────────────┐
│                        プレゼンテーション層                           │
├─────────────────────────────────────────────────────────────────────┤
│  Views                          │  JavaScript Controllers           │
│  ├─ tutorials/                  │  ├─ tutorial_controller.js        │
│  │   ├─ _minimal_tooltip.erb    │  ├─ feedback_controller.js        │
│  │   ├─ _progress_dots.erb      │  ├─ context_help_controller.js    │
│  │   └─ _milestone_badge.erb    │  ├─ progressive_disclosure_ctrl.js│
│  └─ shared/                     │  └─ feature_unlock_controller.js  │
│      └─ _feedback_toast.erb     │                                   │
├─────────────────────────────────────────────────────────────────────┤
│                          アプリケーション層                           │
├─────────────────────────────────────────────────────────────────────┤
│  Controllers                    │  Services                         │
│  ├─ TutorialsController         │  ├─ TutorialProgressService       │
│  └─ FeedbackController          │  ├─ FeatureUnlockService          │
│                                 │  ├─ MilestoneService              │
│  Helpers                        │  └─ TutorialAnalyticsService      │
│  └─ TutorialsHelper             │                                   │
├─────────────────────────────────────────────────────────────────────┤
│                            ドメイン層                                │
├─────────────────────────────────────────────────────────────────────┤
│  Models                         │  Validators                       │
│  ├─ TutorialStep                │  ├─ TutorialStepValidator         │
│  ├─ TutorialProgress            │  └─ ContentLengthValidator        │
│  ├─ UserMilestone               │                                   │
│  └─ FeatureUnlock               │                                   │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 設計方針

| 方針 | 説明 |
|------|------|
| **最小限の介入** | ユーザーの操作を妨げない |
| **即時フィードバック** | すべてのアクションに0.3秒以内で応答 |
| **段階的複雑化** | 初期はシンプル、習熟に応じて拡張 |
| **オフライン対応** | 基本動作はサーバー通信なしで可能 |

---

## 2. データモデル設計

### 2.1 ER図

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│      User        │     │ TutorialProgress │     │  TutorialStep    │
├──────────────────┤     ├──────────────────┤     ├──────────────────┤
│ id               │────<│ user_id          │     │ id               │
│ email            │     │ tutorial_type    │>────│ tutorial_type    │
│ role             │     │ current_step_id  │     │ step_id          │
│ feature_level    │     │ completed        │     │ position         │
│ tutorial_settings│     │ skipped          │     │ title (15文字)   │
└──────────────────┘     │ started_at       │     │ description(40字)│
         │               │ completed_at     │     │ target_selector  │
         │               │ step_times       │     │ action_type      │
         │               └──────────────────┘     │ success_feedback │
         │                                        │ video_url        │
         │               ┌──────────────────┐     └──────────────────┘
         │               │  UserMilestone   │
         └──────────────<├──────────────────┤
                         │ user_id          │
                         │ milestone_type   │
                         │ achieved_at      │
                         │ metadata         │
                         └──────────────────┘

         │               ┌──────────────────┐
         └──────────────<│  FeatureUnlock   │
                         ├──────────────────┤
                         │ user_id          │
                         │ feature_key      │
                         │ unlocked_at      │
                         │ unlock_trigger   │
                         └──────────────────┘
```

### 2.2 マイグレーション

#### 2.2.1 TutorialStep テーブル更新

```ruby
# db/migrate/XXXXXX_update_tutorial_steps_for_v2.rb
class UpdateTutorialStepsForV2 < ActiveRecord::Migration[8.0]
  def change
    # アクションタイプの追加（何をさせるか）
    add_column :tutorial_steps, :action_type, :string, default: 'observe'
    # 成功時のフィードバック設定
    add_column :tutorial_steps, :success_feedback, :jsonb, default: {}
    # 推奨滞在時間（秒）
    add_column :tutorial_steps, :recommended_duration, :integer, default: 5
    # スキップ可能か
    add_column :tutorial_steps, :skippable, :boolean, default: true

    # インデックス追加
    add_index :tutorial_steps, [:tutorial_type, :position]
  end
end
```

#### 2.2.2 TutorialProgress テーブル更新

```ruby
# db/migrate/XXXXXX_update_tutorial_progress_for_v2.rb
class UpdateTutorialProgressForV2 < ActiveRecord::Migration[8.0]
  def change
    # 各ステップの滞在時間を記録
    add_column :tutorial_progresses, :step_times, :jsonb, default: {}
    # スキップしたステップを記録
    add_column :tutorial_progresses, :skipped_steps, :jsonb, default: []
    # 完了方法（completed / skipped_all / auto_completed）
    add_column :tutorial_progresses, :completion_method, :string
  end
end
```

#### 2.2.3 UserMilestone テーブル作成

```ruby
# db/migrate/XXXXXX_create_user_milestones.rb
class CreateUserMilestones < ActiveRecord::Migration[8.0]
  def change
    create_table :user_milestones do |t|
      t.references :user, null: false, foreign_key: true
      t.string :milestone_type, null: false
      t.datetime :achieved_at, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :user_milestones, [:user_id, :milestone_type], unique: true
  end
end
```

#### 2.2.4 FeatureUnlock テーブル作成

```ruby
# db/migrate/XXXXXX_create_feature_unlocks.rb
class CreateFeatureUnlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_unlocks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :feature_key, null: false
      t.datetime :unlocked_at, null: false
      t.string :unlock_trigger  # どのアクションでアンロックされたか

      t.timestamps
    end

    add_index :feature_unlocks, [:user_id, :feature_key], unique: true
  end
end
```

#### 2.2.5 User テーブル更新

```ruby
# db/migrate/XXXXXX_add_feature_level_to_users.rb
class AddFeatureLevelToUsers < ActiveRecord::Migration[8.0]
  def change
    # 機能開放レベル (beginner / intermediate / advanced)
    add_column :users, :feature_level, :string, default: 'beginner'

    add_index :users, :feature_level
  end
end
```

### 2.3 モデル定義

#### 2.3.1 TutorialStep モデル

```ruby
# app/models/tutorial_step.rb
class TutorialStep < ApplicationRecord
  # === 桜井流コンテンツ制約 ===
  MAX_TITLE_LENGTH = 15
  MAX_DESCRIPTION_LENGTH = 40
  MAX_STEPS_PER_TUTORIAL = 5
  RECOMMENDED_DURATION_SECONDS = 5

  # アクションタイプ定義
  ACTION_TYPES = {
    observe: 'observe',      # 見るだけ
    tap: 'tap',              # タップ/クリック
    input: 'input',          # 入力
    select: 'select',        # 選択
    drag: 'drag'             # ドラッグ
  }.freeze

  # バリデーション
  validates :title, presence: true,
                    length: { maximum: MAX_TITLE_LENGTH,
                              message: "は#{MAX_TITLE_LENGTH}文字以内で入力してください" }
  validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH,
                                    message: "は#{MAX_DESCRIPTION_LENGTH}文字以内で入力してください" }
  validates :action_type, inclusion: { in: ACTION_TYPES.values }
  validates :recommended_duration, numericality: { less_than_or_equal_to: 10 }

  validate :title_starts_with_action_verb
  validate :tutorial_step_count_within_limit

  # スコープ
  scope :for_type, ->(type) { where(tutorial_type: type).order(:position) }
  scope :skippable, -> { where(skippable: true) }

  # コールバック
  before_validation :set_defaults

  # === インスタンスメソッド ===

  def action_verb?
    ACTION_VERBS.any? { |verb| title&.start_with?(verb) }
  end

  def feedback_config
    {
      type: success_feedback['type'] || 'default',
      message: success_feedback['message'],
      animation: success_feedback['animation'] || 'pop',
      sound: success_feedback['sound'],
      duration: success_feedback['duration'] || 300
    }
  end

  def as_json_for_tutorial
    {
      id: id,
      step_id: step_id,
      position: position,
      title: title,
      description: description,
      target_selector: target_selector,
      tooltip_position: tooltip_position,
      action_type: action_type,
      feedback: feedback_config,
      skippable: skippable,
      recommended_duration: recommended_duration,
      is_first: first_step?,
      is_last: last_step?,
      video_url: video_url
    }
  end

  private

  ACTION_VERBS = %w[
    タップ クリック 選択 入力 確認
    見て 押して 開いて 選んで 入れて
    ドロップ スワイプ スライド
  ].freeze

  def set_defaults
    self.action_type ||= 'observe'
    self.recommended_duration ||= RECOMMENDED_DURATION_SECONDS
    self.skippable = true if skippable.nil?
  end

  def title_starts_with_action_verb
    return if title.blank?
    return if action_verb?

    # 警告のみ（エラーにはしない）
    Rails.logger.warn "[Tutorial] タイトルは動詞で始めることを推奨: #{title}"
  end

  def tutorial_step_count_within_limit
    return unless new_record?

    current_count = TutorialStep.where(tutorial_type: tutorial_type).count
    if current_count >= MAX_STEPS_PER_TUTORIAL
      errors.add(:base, "チュートリアルは最大#{MAX_STEPS_PER_TUTORIAL}ステップまでです")
    end
  end
end
```

#### 2.3.2 UserMilestone モデル

```ruby
# app/models/user_milestone.rb
class UserMilestone < ApplicationRecord
  belongs_to :user

  # マイルストーン種別
  TYPES = {
    first_vote: 'first_vote',
    first_submission: 'first_submission',
    first_contest_published: 'first_contest_published',
    first_contest_completed: 'first_contest_completed',
    all_entries_judged: 'all_entries_judged',
    tutorial_completed: 'tutorial_completed'
  }.freeze

  # バッジ情報
  BADGES = {
    'first_vote' => { name: '初投票', icon: 'heart', color: 'pink' },
    'first_submission' => { name: 'フォトグラファー', icon: 'camera', color: 'indigo' },
    'first_contest_published' => { name: 'オーガナイザー', icon: 'flag', color: 'green' },
    'first_contest_completed' => { name: 'マスターオーガナイザー', icon: 'trophy', color: 'yellow' },
    'all_entries_judged' => { name: '審査完了', icon: 'check-circle', color: 'blue' },
    'tutorial_completed' => { name: 'チュートリアル完了', icon: 'academic-cap', color: 'purple' }
  }.freeze

  validates :milestone_type, presence: true, inclusion: { in: TYPES.values }
  validates :achieved_at, presence: true

  scope :recent, -> { order(achieved_at: :desc) }

  def badge_info
    BADGES[milestone_type] || { name: milestone_type, icon: 'star', color: 'gray' }
  end

  def self.achieve!(user, milestone_type, metadata = {})
    return if user.milestones.exists?(milestone_type: milestone_type)

    create!(
      user: user,
      milestone_type: milestone_type,
      achieved_at: Time.current,
      metadata: metadata
    )
  end
end
```

#### 2.3.3 FeatureUnlock モデル

```ruby
# app/models/feature_unlock.rb
class FeatureUnlock < ApplicationRecord
  belongs_to :user

  # 機能キー定義
  FEATURES = {
    # 参加者機能
    submit_entry: 'submit_entry',
    comment: 'comment',
    share: 'share',

    # 運営者機能
    create_contest_custom: 'create_contest_custom',
    area_management: 'area_management',
    judge_invitation: 'judge_invitation',
    evaluation_criteria: 'evaluation_criteria',
    statistics: 'statistics',
    result_announcement: 'result_announcement',

    # 管理者機能
    advanced_moderation: 'advanced_moderation',
    system_settings: 'system_settings'
  }.freeze

  # 機能開放トリガー
  UNLOCK_TRIGGERS = {
    'submit_entry' => :first_vote,
    'comment' => :first_vote,
    'create_contest_custom' => :first_contest_published,
    'area_management' => :first_contest_published,
    'judge_invitation' => :first_contest_published,
    'evaluation_criteria' => :first_contest_completed,
    'statistics' => :first_contest_completed,
    'result_announcement' => :first_contest_completed
  }.freeze

  validates :feature_key, presence: true, inclusion: { in: FEATURES.values }
  validates :unlocked_at, presence: true

  scope :for_feature, ->(key) { where(feature_key: key) }

  def self.unlock!(user, feature_key, trigger = nil)
    return if user.feature_unlocks.exists?(feature_key: feature_key)

    create!(
      user: user,
      feature_key: feature_key,
      unlocked_at: Time.current,
      unlock_trigger: trigger
    )
  end

  def self.unlocked?(user, feature_key)
    user.feature_unlocks.exists?(feature_key: feature_key)
  end
end
```

#### 2.3.4 User モデル拡張

```ruby
# app/models/concerns/tutorial_trackable.rb
module TutorialTrackable
  extend ActiveSupport::Concern

  included do
    has_many :milestones, class_name: 'UserMilestone', dependent: :destroy
    has_many :feature_unlocks, dependent: :destroy

    # 機能レベル
    enum :feature_level, {
      beginner: 'beginner',
      intermediate: 'intermediate',
      advanced: 'advanced'
    }, prefix: true
  end

  # === 機能アクセス ===

  def can_access_feature?(feature_key)
    # 基本機能は常にアクセス可能
    return true if basic_feature?(feature_key)

    # アンロック済みならアクセス可能
    feature_unlocks.exists?(feature_key: feature_key)
  end

  def available_features
    base_features = case role
                    when 'participant' then PARTICIPANT_BASE_FEATURES
                    when 'organizer' then ORGANIZER_BASE_FEATURES
                    when 'admin' then ADMIN_BASE_FEATURES
                    else []
                    end

    base_features + feature_unlocks.pluck(:feature_key)
  end

  # === マイルストーン ===

  def achieved_milestone?(milestone_type)
    milestones.exists?(milestone_type: milestone_type)
  end

  def recent_milestones(limit = 5)
    milestones.recent.limit(limit)
  end

  # === 機能レベル更新 ===

  def update_feature_level!
    new_level = calculate_feature_level
    update!(feature_level: new_level) if feature_level != new_level
  end

  private

  PARTICIPANT_BASE_FEATURES = %w[view_contests view_entries vote].freeze
  ORGANIZER_BASE_FEATURES = %w[view_dashboard create_contest_from_template basic_moderation].freeze
  ADMIN_BASE_FEATURES = %w[view_admin_dashboard manage_users manage_contests].freeze

  def basic_feature?(feature_key)
    case role
    when 'participant' then PARTICIPANT_BASE_FEATURES.include?(feature_key)
    when 'organizer' then ORGANIZER_BASE_FEATURES.include?(feature_key)
    when 'admin' then true
    else false
    end
  end

  def calculate_feature_level
    case role
    when 'organizer'
      if achieved_milestone?('first_contest_completed')
        'advanced'
      elsif achieved_milestone?('first_contest_published')
        'intermediate'
      else
        'beginner'
      end
    when 'participant'
      if achieved_milestone?('first_submission')
        'intermediate'
      else
        'beginner'
      end
    else
      'advanced'
    end
  end
end
```

---

## 3. サービス層設計

### 3.1 TutorialProgressService

```ruby
# app/services/tutorial_progress_service.rb
class TutorialProgressService
  def initialize(user)
    @user = user
  end

  # チュートリアル開始
  def start(tutorial_type)
    progress = find_or_initialize_progress(tutorial_type)

    if progress.new_record?
      progress.started_at = Time.current
      progress.current_step_id = first_step_id(tutorial_type)
      progress.save!
    end

    progress
  end

  # ステップ完了
  def complete_step(tutorial_type, step_id, duration_ms = nil)
    progress = find_progress(tutorial_type)
    return nil unless progress

    # 滞在時間を記録
    if duration_ms
      progress.step_times[step_id] = duration_ms
    end

    step = TutorialStep.find_by(tutorial_type: tutorial_type, step_id: step_id)
    next_step = step&.next_step

    if next_step
      progress.current_step_id = next_step.step_id
      progress.save!
    else
      complete_tutorial(progress, 'completed')
    end

    # フィードバックを返す
    {
      progress: progress,
      feedback: step&.feedback_config,
      next_step: next_step&.as_json_for_tutorial,
      completed: progress.completed?
    }
  end

  # スキップ
  def skip_step(tutorial_type, step_id)
    progress = find_progress(tutorial_type)
    return nil unless progress

    progress.skipped_steps << step_id
    step = TutorialStep.find_by(tutorial_type: tutorial_type, step_id: step_id)
    next_step = step&.next_step

    if next_step
      progress.current_step_id = next_step.step_id
      progress.save!
    else
      complete_tutorial(progress, 'skipped_all')
    end

    { progress: progress, next_step: next_step&.as_json_for_tutorial }
  end

  # 全スキップ
  def skip_all(tutorial_type)
    progress = find_or_initialize_progress(tutorial_type)
    complete_tutorial(progress, 'skipped_all')
    progress
  end

  private

  def find_or_initialize_progress(tutorial_type)
    @user.tutorial_progresses.find_or_initialize_by(tutorial_type: tutorial_type)
  end

  def find_progress(tutorial_type)
    @user.tutorial_progresses.find_by(tutorial_type: tutorial_type)
  end

  def first_step_id(tutorial_type)
    TutorialStep.for_type(tutorial_type).first&.step_id
  end

  def complete_tutorial(progress, method)
    progress.completed = true
    progress.completed_at = Time.current
    progress.completion_method = method
    progress.save!

    # マイルストーン達成
    MilestoneService.new(@user).check_tutorial_milestone(progress.tutorial_type)
  end
end
```

### 3.2 MilestoneService

```ruby
# app/services/milestone_service.rb
class MilestoneService
  def initialize(user)
    @user = user
  end

  # アクションに応じたマイルストーンチェック
  def check_and_award(action, metadata = {})
    case action
    when :vote
      check_first_vote(metadata)
    when :submit_entry
      check_first_submission(metadata)
    when :publish_contest
      check_first_contest_published(metadata)
    when :complete_contest
      check_first_contest_completed(metadata)
    when :complete_judging
      check_all_entries_judged(metadata)
    end

    # 機能レベル更新
    @user.update_feature_level!
  end

  def check_tutorial_milestone(tutorial_type)
    UserMilestone.achieve!(@user, 'tutorial_completed', { tutorial_type: tutorial_type })
  end

  private

  def check_first_vote(metadata)
    return if @user.achieved_milestone?('first_vote')

    UserMilestone.achieve!(@user, 'first_vote', metadata)

    # 関連機能をアンロック
    FeatureUnlockService.new(@user).unlock_for_trigger(:first_vote)

    # フィードバック通知を送信
    broadcast_achievement('first_vote')
  end

  def check_first_submission(metadata)
    return if @user.achieved_milestone?('first_submission')

    UserMilestone.achieve!(@user, 'first_submission', metadata)
    broadcast_achievement('first_submission')
  end

  def check_first_contest_published(metadata)
    return if @user.achieved_milestone?('first_contest_published')

    UserMilestone.achieve!(@user, 'first_contest_published', metadata)
    FeatureUnlockService.new(@user).unlock_for_trigger(:first_contest_published)
    broadcast_achievement('first_contest_published')
  end

  def check_first_contest_completed(metadata)
    return if @user.achieved_milestone?('first_contest_completed')

    UserMilestone.achieve!(@user, 'first_contest_completed', metadata)
    FeatureUnlockService.new(@user).unlock_for_trigger(:first_contest_completed)
    broadcast_achievement('first_contest_completed')
  end

  def check_all_entries_judged(metadata)
    return if @user.achieved_milestone?('all_entries_judged')

    UserMilestone.achieve!(@user, 'all_entries_judged', metadata)
    broadcast_achievement('all_entries_judged')
  end

  def broadcast_achievement(milestone_type)
    badge = UserMilestone::BADGES[milestone_type]

    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{@user.id}_notifications",
      target: "milestone-notifications",
      partial: "tutorials/milestone_notification",
      locals: { badge: badge }
    )
  end
end
```

### 3.3 FeatureUnlockService

```ruby
# app/services/feature_unlock_service.rb
class FeatureUnlockService
  def initialize(user)
    @user = user
  end

  def unlock_for_trigger(trigger)
    features_to_unlock = FeatureUnlock::UNLOCK_TRIGGERS.select { |_, t| t == trigger }.keys

    features_to_unlock.each do |feature_key|
      FeatureUnlock.unlock!(@user, feature_key, trigger.to_s)
    end

    broadcast_unlocks(features_to_unlock) if features_to_unlock.any?
  end

  def unlock_feature(feature_key, trigger = nil)
    FeatureUnlock.unlock!(@user, feature_key, trigger)
  end

  private

  def broadcast_unlocks(feature_keys)
    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{@user.id}_notifications",
      target: "feature-unlocks",
      partial: "tutorials/feature_unlock_notification",
      locals: { features: feature_keys }
    )
  end
end
```

---

## 4. コントローラー設計

### 4.1 TutorialsController 更新

```ruby
# app/controllers/tutorials_controller.rb
class TutorialsController < ApplicationController
  before_action :authenticate_user!

  # GET /tutorials/:tutorial_type
  def show
    steps = TutorialStep.for_type(params[:tutorial_type])
    progress = current_user.tutorial_progresses.find_by(tutorial_type: params[:tutorial_type])

    render json: {
      steps: steps.map(&:as_json_for_tutorial),
      progress: progress_json(progress),
      settings: tutorial_settings
    }
  end

  # POST /tutorials/:tutorial_type/start
  def start
    service = TutorialProgressService.new(current_user)
    progress = service.start(params[:tutorial_type])

    render json: { progress: progress_json(progress) }
  end

  # PATCH /tutorials/:tutorial_type
  def update
    service = TutorialProgressService.new(current_user)
    result = service.complete_step(
      params[:tutorial_type],
      params[:step_id],
      params[:duration_ms]
    )

    if result
      render json: result
    else
      render json: { error: 'Progress not found' }, status: :not_found
    end
  end

  # POST /tutorials/:tutorial_type/skip
  def skip
    service = TutorialProgressService.new(current_user)

    result = if params[:skip_all]
               { progress: service.skip_all(params[:tutorial_type]) }
             else
               service.skip_step(params[:tutorial_type], params[:step_id])
             end

    render json: result
  end

  # GET /tutorials/status
  def status
    progresses = current_user.tutorial_progresses.index_by(&:tutorial_type)

    render json: {
      progresses: progresses.transform_values { |p| progress_json(p) },
      should_show_onboarding: should_show_onboarding?,
      onboarding_type: onboarding_tutorial_type,
      feature_level: current_user.feature_level,
      available_features: current_user.available_features
    }
  end

  private

  def progress_json(progress)
    return nil unless progress

    {
      tutorial_type: progress.tutorial_type,
      current_step_id: progress.current_step_id,
      completed: progress.completed,
      skipped: progress.skipped,
      started_at: progress.started_at,
      completed_at: progress.completed_at,
      completion_method: progress.completion_method
    }
  end

  def tutorial_settings
    settings = current_user.tutorial_settings || {}
    {
      show_tutorials: settings.fetch('show_tutorials', true),
      show_context_help: settings.fetch('show_context_help', true),
      reduced_motion: settings.fetch('reduced_motion', false)
    }
  end

  def should_show_onboarding?
    type = onboarding_tutorial_type
    return false unless type

    progress = current_user.tutorial_progresses.find_by(tutorial_type: type)
    progress.nil? || (!progress.completed && !progress.skipped)
  end

  def onboarding_tutorial_type
    TutorialStep.onboarding_type_for_role(current_user.role)
  end
end
```

### 4.2 FeedbackController（新規）

```ruby
# app/controllers/feedback_controller.rb
class FeedbackController < ApplicationController
  before_action :authenticate_user!

  # POST /feedback/action
  def action
    action_type = params[:action_type]
    metadata = params[:metadata] || {}

    # マイルストーンチェック
    service = MilestoneService.new(current_user)
    service.check_and_award(action_type.to_sym, metadata)

    render json: {
      milestones: current_user.recent_milestones(3).map { |m| m.badge_info },
      feature_level: current_user.feature_level
    }
  end
end
```

---

## 5. フロントエンド設計

### 5.1 Stimulus コントローラー

#### 5.1.1 tutorial_controller.js（更新）

```javascript
// app/javascript/controllers/tutorial_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "tooltip", "progress"]
  static values = {
    tutorialType: String,
    autoStart: { type: Boolean, default: false },
    reducedMotion: { type: Boolean, default: false }
  }

  // 桜井流制約
  static MAX_STEP_DURATION = 10000  // 10秒
  static ANIMATION_DURATION = 300    // 0.3秒

  connect() {
    this.steps = []
    this.currentStepIndex = 0
    this.stepStartTime = null

    if (this.autoStartValue) {
      this.checkAndStart()
    }
  }

  async start() {
    this.isActive = true
    await this.loadTutorial()
    this.showStep(0)
  }

  showStep(index) {
    const step = this.steps[index]
    if (!step) {
      this.complete()
      return
    }

    this.currentStepIndex = index
    this.stepStartTime = Date.now()

    // ターゲット要素のハイライト
    this.highlightTarget(step)

    // ミニマルツールチップ表示
    this.showMinimalTooltip(step)

    // プログレス更新
    this.updateProgress(index)

    // 自動進行タイマー（オプション）
    if (step.auto_advance) {
      this.autoAdvanceTimer = setTimeout(() => {
        this.next()
      }, step.recommended_duration * 1000)
    }
  }

  showMinimalTooltip(step) {
    const tooltip = this.tooltipTarget
    tooltip.innerHTML = this.buildMinimalTooltip(step)
    tooltip.classList.remove('hidden')

    // 位置調整
    this.positionTooltip(tooltip, step)

    // アニメーション
    if (!this.reducedMotionValue) {
      tooltip.style.animation = `tooltip-appear ${this.constructor.ANIMATION_DURATION}ms ease-out`
    }
  }

  buildMinimalTooltip(step) {
    // 桜井流：最小限のUI
    return `
      <div class="tutorial-minimal-tooltip">
        <p class="tutorial-title">${this.escapeHtml(step.title)}</p>
        ${step.description ? `<p class="tutorial-desc">${this.escapeHtml(step.description)}</p>` : ''}
        <div class="tutorial-actions">
          <button data-action="tutorial#skip" class="tutorial-skip">
            スキップ
          </button>
          <button data-action="tutorial#next" class="tutorial-next">
            ${step.is_last ? '完了' : '次へ'}
          </button>
        </div>
      </div>
      <div class="tutorial-progress-dots">
        ${this.buildProgressDots()}
      </div>
    `
  }

  buildProgressDots() {
    return this.steps.map((_, i) => {
      const state = i < this.currentStepIndex ? 'completed' :
                    i === this.currentStepIndex ? 'current' : 'pending'
      return `<span class="tutorial-dot tutorial-dot--${state}"></span>`
    }).join('')
  }

  async next() {
    clearTimeout(this.autoAdvanceTimer)

    const step = this.steps[this.currentStepIndex]
    const duration = Date.now() - this.stepStartTime

    // ステップ完了を記録
    const result = await this.completeStep(step.step_id, duration)

    // フィードバック表示
    if (result.feedback) {
      this.showFeedback(result.feedback)
    }

    // 次のステップへ
    this.clearHighlight()

    if (result.completed) {
      this.complete()
    } else {
      this.showStep(this.currentStepIndex + 1)
    }
  }

  async skip() {
    clearTimeout(this.autoAdvanceTimer)

    const step = this.steps[this.currentStepIndex]
    await this.skipStep(step.step_id)

    this.clearHighlight()

    if (this.currentStepIndex >= this.steps.length - 1) {
      this.cleanup()
    } else {
      this.showStep(this.currentStepIndex + 1)
    }
  }

  showFeedback(config) {
    // 即時フィードバック（0.2秒以内）
    const event = new CustomEvent('tutorial:feedback', {
      detail: {
        type: config.type,
        message: config.message,
        animation: config.animation
      }
    })
    document.dispatchEvent(event)
  }

  complete() {
    this.cleanup()

    // 完了フィードバック
    this.showCompletionFeedback()

    // イベント発火
    this.element.dispatchEvent(new CustomEvent('tutorial:completed', {
      bubbles: true,
      detail: { tutorialType: this.tutorialTypeValue }
    }))
  }

  showCompletionFeedback() {
    // 桜井流：シンプルで心地よい完了表現
    const toast = document.createElement('div')
    toast.className = 'tutorial-completion-toast'
    toast.innerHTML = `
      <svg class="completion-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      <span>準備完了！</span>
    `
    document.body.appendChild(toast)

    setTimeout(() => toast.remove(), 2000)
  }
}
```

#### 5.1.2 feedback_controller.js（新規）

```javascript
// app/javascript/controllers/feedback_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    action: String,
    successMessage: { type: String, default: '完了！' }
  }

  // 即時フィードバック（桜井流：0.2秒以内）
  static FEEDBACK_DELAY = 200

  connect() {
    document.addEventListener('tutorial:feedback', this.handleFeedback.bind(this))
  }

  disconnect() {
    document.removeEventListener('tutorial:feedback', this.handleFeedback.bind(this))
  }

  // アクション完了時のフィードバック
  success(event) {
    event?.preventDefault()

    // 視覚フィードバック
    this.showVisualFeedback('success')

    // サーバーに通知（非同期）
    this.notifyServer()
  }

  showVisualFeedback(type) {
    // ポップアニメーション
    this.element.classList.add('feedback-pop')

    // 成功インジケーター
    this.showIndicator(type)

    // クリーンアップ
    setTimeout(() => {
      this.element.classList.remove('feedback-pop')
    }, 300)
  }

  showIndicator(type) {
    const indicator = document.createElement('div')
    indicator.className = `feedback-indicator feedback-indicator--${type}`
    indicator.innerHTML = this.getIndicatorContent(type)

    this.element.appendChild(indicator)

    setTimeout(() => {
      indicator.classList.add('feedback-indicator--visible')
    }, 10)

    setTimeout(() => {
      indicator.classList.remove('feedback-indicator--visible')
      setTimeout(() => indicator.remove(), 150)
    }, 1500)
  }

  getIndicatorContent(type) {
    switch (type) {
      case 'success':
        return `
          <svg class="indicator-icon" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
          </svg>
          <span>${this.successMessageValue}</span>
        `
      case 'milestone':
        return `
          <svg class="indicator-icon" viewBox="0 0 20 20" fill="currentColor">
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
          </svg>
          <span>バッジ獲得！</span>
        `
      default:
        return ''
    }
  }

  handleFeedback(event) {
    const { type, message, animation } = event.detail
    this.showVisualFeedback(type)
  }

  async notifyServer() {
    if (!this.actionValue) return

    try {
      await fetch('/feedback/action', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          action_type: this.actionValue
        })
      })
    } catch (error) {
      console.error('Feedback notification failed:', error)
    }
  }
}
```

#### 5.1.3 progressive_disclosure_controller.js（新規）

```javascript
// app/javascript/controllers/progressive_disclosure_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["basic", "advanced", "toggle"]
  static values = {
    expanded: { type: Boolean, default: false },
    featureLevel: { type: String, default: 'beginner' }
  }

  connect() {
    this.updateVisibility()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.updateVisibility()
  }

  updateVisibility() {
    // 基本フィールドは常に表示
    this.basicTargets.forEach(el => el.classList.remove('hidden'))

    // 上級フィールドの表示制御
    if (this.expandedValue || this.featureLevelValue !== 'beginner') {
      this.advancedTargets.forEach(el => el.classList.remove('hidden'))
      this.updateToggleText('シンプル表示に戻す')
    } else {
      this.advancedTargets.forEach(el => el.classList.add('hidden'))
      this.updateToggleText('詳細設定を表示')
    }
  }

  updateToggleText(text) {
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = text
    }
  }
}
```

### 5.2 CSS設計

```css
/* app/assets/stylesheets/tutorial_v2.css */

/* =============================================
   桜井流チュートリアルスタイル v2
   - シンプル
   - 即時反応
   - 心地よいアニメーション
   ============================================= */

/* === 基本変数 === */
:root {
  --tutorial-primary: #4f46e5;
  --tutorial-success: #10b981;
  --tutorial-animation-fast: 150ms;
  --tutorial-animation-normal: 300ms;
}

/* === ミニマルツールチップ === */
.tutorial-minimal-tooltip {
  background: white;
  border-radius: 12px;
  box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.15);
  padding: 16px 20px;
  max-width: 260px;
  min-width: 180px;
}

.tutorial-title {
  font-size: 15px;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 4px;
}

.tutorial-desc {
  font-size: 13px;
  color: #6b7280;
  margin: 0 0 12px;
  line-height: 1.4;
}

.tutorial-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.tutorial-skip {
  padding: 6px 12px;
  font-size: 13px;
  color: #9ca3af;
  background: none;
  border: none;
  cursor: pointer;
  transition: color var(--tutorial-animation-fast);
}

.tutorial-skip:hover {
  color: #6b7280;
}

.tutorial-next {
  padding: 6px 16px;
  font-size: 13px;
  font-weight: 500;
  color: white;
  background: var(--tutorial-primary);
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: background var(--tutorial-animation-fast);
}

.tutorial-next:hover {
  background: #4338ca;
}

/* === プログレスドット（桜井流：シンプル） === */
.tutorial-progress-dots {
  display: flex;
  justify-content: center;
  gap: 6px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #f3f4f6;
}

.tutorial-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  transition: all var(--tutorial-animation-fast);
}

.tutorial-dot--pending {
  background: #e5e7eb;
}

.tutorial-dot--current {
  background: var(--tutorial-primary);
  transform: scale(1.3);
}

.tutorial-dot--completed {
  background: var(--tutorial-success);
}

/* === ハイライト（控えめ） === */
.tutorial-highlight {
  position: relative;
  z-index: 50;
  box-shadow: 0 0 0 3px var(--tutorial-primary),
              0 0 0 6px rgba(79, 70, 229, 0.2);
  border-radius: 8px;
}

/* パルスアニメーション（桜井流：控えめ） */
@keyframes tutorial-subtle-pulse {
  0%, 100% {
    box-shadow: 0 0 0 3px var(--tutorial-primary),
                0 0 0 6px rgba(79, 70, 229, 0.2);
  }
  50% {
    box-shadow: 0 0 0 3px var(--tutorial-primary),
                0 0 0 10px rgba(79, 70, 229, 0.1);
  }
}

.tutorial-highlight {
  animation: tutorial-subtle-pulse 2s ease-in-out infinite;
}

/* === フィードバックアニメーション === */
.feedback-pop {
  animation: feedback-pop var(--tutorial-animation-normal) ease-out;
}

@keyframes feedback-pop {
  0% { transform: scale(1); }
  50% { transform: scale(1.08); }
  100% { transform: scale(1); }
}

/* === フィードバックインジケーター === */
.feedback-indicator {
  position: absolute;
  top: -8px;
  right: -8px;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  background: var(--tutorial-success);
  color: white;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
  opacity: 0;
  transform: translateY(-4px);
  transition: all var(--tutorial-animation-fast);
  z-index: 100;
}

.feedback-indicator--visible {
  opacity: 1;
  transform: translateY(0);
}

.feedback-indicator .indicator-icon {
  width: 14px;
  height: 14px;
}

/* === 完了トースト === */
.tutorial-completion-toast {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  background: var(--tutorial-success);
  color: white;
  border-radius: 24px;
  font-size: 14px;
  font-weight: 500;
  box-shadow: 0 10px 30px -5px rgba(16, 185, 129, 0.4);
  animation: toast-appear 0.3s ease-out, toast-disappear 0.3s ease-out 1.7s forwards;
  z-index: 9999;
}

.tutorial-completion-toast .completion-icon {
  width: 20px;
  height: 20px;
}

@keyframes toast-appear {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
}

@keyframes toast-disappear {
  from {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
  to {
    opacity: 0;
    transform: translateX(-50%) translateY(-10px);
  }
}

/* === マイルストーンバッジ === */
.milestone-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: linear-gradient(135deg, #fef3c7, #fde68a);
  color: #92400e;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(251, 191, 36, 0.3);
}

.milestone-badge--new {
  animation: badge-appear 0.5s ease-out;
}

@keyframes badge-appear {
  0% {
    opacity: 0;
    transform: scale(0.5) rotate(-10deg);
  }
  50% {
    transform: scale(1.1) rotate(5deg);
  }
  100% {
    opacity: 1;
    transform: scale(1) rotate(0);
  }
}

/* === モーション軽減 === */
@media (prefers-reduced-motion: reduce) {
  .tutorial-highlight,
  .feedback-pop,
  .feedback-indicator,
  .tutorial-completion-toast,
  .milestone-badge--new {
    animation: none !important;
    transition: none !important;
  }
}

/* === モバイル対応 === */
@media (max-width: 640px) {
  .tutorial-minimal-tooltip {
    max-width: calc(100vw - 32px);
    padding: 14px 16px;
  }

  .tutorial-title {
    font-size: 14px;
  }

  .tutorial-desc {
    font-size: 12px;
  }
}
```

---

## 6. ビュー設計

### 6.1 パーシャル

#### 6.1.1 ミニマルツールチップ

```erb
<%# app/views/tutorials/_minimal_tooltip.html.erb %>
<div class="tutorial-minimal-tooltip"
     data-tutorial-target="tooltip"
     role="tooltip"
     aria-live="polite">
  <%# 動的にJavaScriptで内容が挿入される %>
</div>
```

#### 6.1.2 プログレスドット

```erb
<%# app/views/tutorials/_progress_dots.html.erb %>
<%# steps: TutorialStep[], current_index: Integer %>
<div class="tutorial-progress-dots" aria-label="進捗: <%= current_index + 1 %>/<%= steps.count %>">
  <% steps.each_with_index do |step, index| %>
    <span class="tutorial-dot tutorial-dot--<%= progress_state(index, current_index) %>"
          aria-hidden="true"></span>
  <% end %>
</div>
```

#### 6.1.3 マイルストーン通知

```erb
<%# app/views/tutorials/_milestone_notification.html.erb %>
<%# badge: { name:, icon:, color: } %>
<div class="milestone-notification" data-controller="auto-dismiss" data-auto-dismiss-delay-value="5000">
  <div class="milestone-badge milestone-badge--new milestone-badge--<%= badge[:color] %>">
    <%= render "icons/#{badge[:icon]}", class: "milestone-icon" %>
    <span><%= badge[:name] %></span>
  </div>
</div>
```

#### 6.1.4 機能アンロック通知

```erb
<%# app/views/tutorials/_feature_unlock_notification.html.erb %>
<%# features: String[] %>
<div class="feature-unlock-notification" data-controller="auto-dismiss">
  <div class="unlock-content">
    <div class="unlock-icon">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z"/>
      </svg>
    </div>
    <div class="unlock-text">
      <p class="unlock-title">新機能が使えるようになりました</p>
      <p class="unlock-features">
        <%= features.map { |f| feature_label(f) }.join('、') %>
      </p>
    </div>
  </div>
</div>
```

### 6.2 段階的開示フォーム

```erb
<%# app/views/organizers/contests/_form_progressive.html.erb %>
<%= form_with model: [:organizers, contest], data: {
  controller: "progressive-disclosure",
  "progressive-disclosure-feature-level-value": current_user.feature_level
} do |f| %>

  <%# === 基本フィールド（常に表示） === %>
  <div data-progressive-disclosure-target="basic" class="space-y-4">
    <div class="form-group">
      <%= f.label :title, "タイトル", class: "form-label" %>
      <%= f.text_field :title,
          class: "form-input",
          placeholder: "コンテストのタイトル",
          required: true,
          maxlength: 100 %>
    </div>

    <div class="form-group">
      <%= f.label :theme, "テーマ（任意）", class: "form-label" %>
      <%= f.text_field :theme,
          class: "form-input",
          placeholder: "例：春の風景" %>
    </div>

    <div class="form-group">
      <%= f.label :entry_end_at, "応募締切", class: "form-label" %>
      <%= f.datetime_local_field :entry_end_at,
          class: "form-input",
          required: true %>
    </div>
  </div>

  <%# === 詳細フィールド（展開時のみ） === %>
  <div data-progressive-disclosure-target="advanced" class="hidden space-y-4 pt-4 border-t">
    <div class="form-group">
      <%= f.label :description, "詳細説明", class: "form-label" %>
      <%= f.text_area :description,
          class: "form-input",
          rows: 4,
          placeholder: "コンテストの詳細な説明..." %>
    </div>

    <div class="form-group">
      <%= f.label :category_id, "カテゴリ", class: "form-label" %>
      <%= f.collection_select :category_id, Category.all, :id, :name,
          { include_blank: "選択してください" },
          { class: "form-select" } %>
    </div>

    <div class="form-group">
      <%= f.label :entry_start_at, "応募開始日時", class: "form-label" %>
      <%= f.datetime_local_field :entry_start_at, class: "form-input" %>
    </div>

    <%# 他の詳細フィールド... %>
  </div>

  <%# === 展開トグル === %>
  <div class="mt-4">
    <button type="button"
            class="text-sm text-indigo-600 hover:text-indigo-800"
            data-progressive-disclosure-target="toggle"
            data-action="progressive-disclosure#toggle">
      詳細設定を表示
    </button>
  </div>

  <%# === 送信ボタン === %>
  <div class="mt-6 flex justify-end gap-3">
    <%= link_to "キャンセル", organizers_contests_path, class: "btn btn-secondary" %>
    <%= f.submit "コンテストを作成",
        class: "btn btn-primary",
        data: { controller: "feedback", feedback_action_value: "publish_contest" } %>
  </div>
<% end %>
```

---

## 7. シードデータ設計

### 7.1 チュートリアルステップ（v2）

```ruby
# db/seeds/tutorial_steps_v2.rb

# 既存データをクリア
TutorialStep.delete_all

# ========================================
# 参加者オンボーディング（3ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: 'participant_onboarding',
    step_id: 'tap_entry',
    position: 1,
    title: '作品をタップ',
    description: '気になる写真を選んでみましょう',
    target_selector: '[data-tutorial="gallery-grid"] a:first-child',
    tooltip_position: 'bottom',
    action_type: 'tap',
    recommended_duration: 5,
    success_feedback: {
      type: 'subtle',
      animation: 'pop'
    }
  },
  {
    tutorial_type: 'participant_onboarding',
    step_id: 'vote',
    position: 2,
    title: 'ハートをタップ',
    description: '素敵な作品に投票できます',
    target_selector: '[data-tutorial="vote-button"]',
    tooltip_position: 'top',
    action_type: 'tap',
    recommended_duration: 5,
    success_feedback: {
      type: 'celebration',
      message: '初投票！',
      animation: 'heart-burst'
    }
  },
  {
    tutorial_type: 'participant_onboarding',
    step_id: 'complete',
    position: 3,
    title: '準備完了！',
    description: 'さあ、楽しみましょう',
    target_selector: nil,
    tooltip_position: 'center',
    action_type: 'observe',
    recommended_duration: 3,
    success_feedback: {
      type: 'completion',
      message: '準備完了！'
    }
  }
])

# ========================================
# 運営者オンボーディング（3ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: 'organizer_onboarding',
    step_id: 'create_button',
    position: 1,
    title: '作成ボタン',
    description: 'コンテストを作りましょう',
    target_selector: '[data-tutorial="create-contest"]',
    tooltip_position: 'bottom',
    action_type: 'tap',
    recommended_duration: 5,
    success_feedback: { type: 'subtle' }
  },
  {
    tutorial_type: 'organizer_onboarding',
    step_id: 'template',
    position: 2,
    title: 'テンプレート選択',
    description: 'おすすめ設定で簡単スタート',
    target_selector: '[data-tutorial="contest-templates"]',
    tooltip_position: 'right',
    action_type: 'select',
    recommended_duration: 5,
    success_feedback: { type: 'subtle' }
  },
  {
    tutorial_type: 'organizer_onboarding',
    step_id: 'publish',
    position: 3,
    title: 'タイトルを入れて公開',
    description: 'これだけで公開できます',
    target_selector: '[data-tutorial="publish-button"]',
    tooltip_position: 'top',
    action_type: 'tap',
    recommended_duration: 5,
    success_feedback: {
      type: 'celebration',
      message: '公開しました！',
      animation: 'confetti'
    }
  }
])

# ========================================
# 審査員オンボーディング（2ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: 'judge_onboarding',
    step_id: 'select_entry',
    position: 1,
    title: '作品を選択',
    description: '審査する作品をタップ',
    target_selector: '[data-tutorial="judge-assignments"] a:first-child',
    tooltip_position: 'bottom',
    action_type: 'tap',
    recommended_duration: 5,
    success_feedback: { type: 'subtle' }
  },
  {
    tutorial_type: 'judge_onboarding',
    step_id: 'score',
    position: 2,
    title: 'スライダーで評価',
    description: '直感で評価してください',
    target_selector: '[data-tutorial="score-input"]',
    tooltip_position: 'left',
    action_type: 'drag',
    recommended_duration: 5,
    success_feedback: {
      type: 'completion',
      message: '評価を保存'
    }
  }
])

# ========================================
# 写真投稿チュートリアル（3ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: 'photo_submission',
    step_id: 'select_photo',
    position: 1,
    title: '写真を選択',
    description: 'ドロップまたはタップ',
    target_selector: '[data-tutorial="photo-upload"]',
    tooltip_position: 'bottom',
    action_type: 'tap',
    recommended_duration: 5,
    success_feedback: { type: 'subtle' }
  },
  {
    tutorial_type: 'photo_submission',
    step_id: 'title',
    position: 2,
    title: 'タイトルを入力',
    description: '作品の名前をつけましょう',
    target_selector: '[data-tutorial="entry-title"]',
    tooltip_position: 'top',
    action_type: 'input',
    recommended_duration: 5,
    success_feedback: { type: 'subtle' }
  },
  {
    tutorial_type: 'photo_submission',
    step_id: 'submit',
    position: 3,
    title: '投稿ボタン',
    description: 'これで投稿完了！',
    target_selector: '[data-tutorial="entry-submit"]',
    tooltip_position: 'top',
    action_type: 'tap',
    recommended_duration: 5,
    success_feedback: {
      type: 'celebration',
      message: '投稿完了！',
      animation: 'pop'
    }
  }
])

# ========================================
# 管理者オンボーディング（2ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: 'admin_onboarding',
    step_id: 'nav_overview',
    position: 1,
    title: 'ナビゲーション',
    description: '各メニューで管理できます',
    target_selector: '[data-tutorial="admin-nav"]',
    tooltip_position: 'bottom',
    action_type: 'observe',
    recommended_duration: 5,
    success_feedback: { type: 'subtle' }
  },
  {
    tutorial_type: 'admin_onboarding',
    step_id: 'stats',
    position: 2,
    title: 'ダッシュボード',
    description: 'ここで状況を把握',
    target_selector: '[data-tutorial="admin-stats"]',
    tooltip_position: 'bottom',
    action_type: 'observe',
    recommended_duration: 5,
    success_feedback: {
      type: 'completion',
      message: '準備完了！'
    }
  }
])

puts "Tutorial steps v2 created: #{TutorialStep.count} steps"
```

---

## 8. ルーティング更新

```ruby
# config/routes.rb（追加部分）

# Tutorials API（更新）
resources :tutorials, param: :tutorial_type, only: [:show, :update] do
  member do
    post :start
    post :skip
    post :reset
  end
  collection do
    get :status
    patch :settings, action: :update_settings
  end
end

# Feedback API（新規）
post '/feedback/action', to: 'feedback#action'

# Feature check（新規）
get '/features/check/:feature_key', to: 'features#check'
```

---

## 9. テスト設計

### 9.1 モデルテスト

```ruby
# spec/models/tutorial_step_spec.rb
RSpec.describe TutorialStep do
  describe 'バリデーション' do
    it 'タイトルは15文字以内' do
      step = build(:tutorial_step, title: 'あ' * 16)
      expect(step).not_to be_valid
      expect(step.errors[:title]).to include('は15文字以内で入力してください')
    end

    it '説明文は40文字以内' do
      step = build(:tutorial_step, description: 'あ' * 41)
      expect(step).not_to be_valid
    end

    it 'チュートリアルごとに最大5ステップ' do
      create_list(:tutorial_step, 5, tutorial_type: 'test_tutorial')
      step = build(:tutorial_step, tutorial_type: 'test_tutorial')
      expect(step).not_to be_valid
    end
  end
end
```

### 9.2 サービステスト

```ruby
# spec/services/milestone_service_spec.rb
RSpec.describe MilestoneService do
  let(:user) { create(:user, :participant) }
  let(:service) { described_class.new(user) }

  describe '#check_and_award' do
    context '初投票時' do
      it 'マイルストーンを付与する' do
        expect {
          service.check_and_award(:vote)
        }.to change { user.milestones.count }.by(1)
      end

      it '関連機能をアンロックする' do
        expect {
          service.check_and_award(:vote)
        }.to change { user.feature_unlocks.count }.by_at_least(1)
      end
    end
  end
end
```

---

## 10. 移行計画

### 10.1 フェーズ1: データベース準備

```bash
# マイグレーション実行
bundle exec rails db:migrate

# シードデータ投入
bundle exec rails db:seed:tutorial_steps_v2
```

### 10.2 フェーズ2: 機能リリース

1. 新しいStimulusコントローラーをデプロイ
2. CSSをデプロイ
3. フィーチャーフラグで段階的に有効化

### 10.3 フェーズ3: 既存ユーザー移行

```ruby
# 既存ユーザーの機能レベルを設定
User.find_each do |user|
  user.update_feature_level!
end
```

---

## 付録

### A. チェックリスト

新しいチュートリアルステップを追加する際：

- [ ] タイトルは15文字以内か
- [ ] タイトルは動詞で始まっているか
- [ ] 説明文は40文字以内か
- [ ] 1ステップ＝1アクションか
- [ ] 推奨滞在時間は10秒以内か
- [ ] 成功フィードバックが設定されているか
- [ ] モバイルで動作確認したか
- [ ] アクセシビリティを確認したか

### B. パフォーマンス目標

| 指標 | 目標値 |
|------|--------|
| チュートリアルJS読み込み | < 50KB gzipped |
| 初回表示まで | < 100ms |
| ステップ切り替え | < 50ms |
| フィードバック表示 | < 200ms |

---

*設計書バージョン: 2.0*
*最終更新: 2026年2月*
