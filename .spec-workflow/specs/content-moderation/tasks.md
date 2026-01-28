# Tasks Document: Content Moderation

## Phase 1: データベース・モデル層

- [x] 1.1. ModerationResultモデルとマイグレーション作成
  - Files: `db/migrate/xxx_create_moderation_results.rb`, `app/models/moderation_result.rb`
  - ModerationResultテーブルを作成（entry_id, provider, status, labels, max_confidence, raw_response, reviewed_by_id, reviewed_at, review_note）
  - ModerationResultモデルを作成（enum status、バリデーション、アソシエーション）
  - Purpose: モデレーション結果を永続化するデータ層の基盤
  - _Leverage: app/models/entry.rb, db/schema.rb_
  - _Requirements: REQ-1, REQ-2_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in Active Record migrations and models | Task: Create ModerationResult migration and model with enum status (pending, approved, rejected, requires_review), JSONB columns for labels and raw_response, associations to Entry and User (reviewer), following existing model patterns in app/models/ | Restrictions: Do not modify existing Entry model yet, follow Rails migration best practices, use JSONB for PostgreSQL compatibility | Success: Migration runs without errors, model has proper validations and associations, specs pass | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 1.2. Entryモデルにmoderation_statusカラム追加
  - Files: `db/migrate/xxx_add_moderation_status_to_entries.rb`, `app/models/entry.rb`
  - Entryテーブルにmoderation_statusカラム追加（enum: pending, approved, hidden, requires_review）
  - Entryモデルにenum、スコープ、ModerationResultアソシエーション追加
  - Purpose: エントリーのモデレーション状態を管理
  - _Leverage: app/models/entry.rb_
  - _Requirements: REQ-1_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer with Active Record expertise | Task: Add moderation_status column to entries table with migration, add enum definition to Entry model with scopes (visible, hidden, requires_review), add has_one :moderation_result association | Restrictions: Default status should be pending, maintain backward compatibility with existing code, add index for status column | Success: Migration runs, enum works correctly, existing entry tests still pass | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 1.3. Contestモデルにモデレーション設定追加
  - Files: `db/migrate/xxx_add_moderation_settings_to_contests.rb`, `app/models/contest.rb`
  - Contestテーブルにmoderation_enabled（default: true）、moderation_threshold（default: 60.0）追加
  - Contestモデルにモデレーション設定アクセサ追加
  - Purpose: コンテスト単位でモデレーション動作を制御
  - _Leverage: app/models/contest.rb_
  - _Requirements: REQ-3_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add moderation_enabled (boolean, default true) and moderation_threshold (decimal, default 60.0) columns to contests table, add helper methods to Contest model for checking moderation settings | Restrictions: Use sensible defaults, add validation for threshold range (0-100), maintain existing Contest functionality | Success: Migration runs, contest settings are accessible, existing tests pass | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 1.4. モデル単体テスト作成
  - Files: `spec/models/moderation_result_spec.rb`, `spec/factories/moderation_results.rb`
  - ModerationResultモデルのバリデーション、アソシエーション、enumテスト
  - Entry、Contestのモデレーション関連テスト追加
  - Purpose: モデル層の品質保証
  - _Leverage: spec/models/entry_spec.rb, spec/factories/entries.rb_
  - _Requirements: REQ-1, REQ-2, REQ-3_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Engineer with RSpec expertise | Task: Create comprehensive model specs for ModerationResult including validations, associations, status transitions, and factory. Add specs for Entry moderation_status and Contest moderation settings | Restrictions: Follow existing spec patterns, use FactoryBot, test both valid and invalid cases | Success: All model specs pass, good coverage of edge cases | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

## Phase 2: サービス層（プロバイダー抽象化）

- [x] 2.1. プロバイダー基底クラスとレジストリ作成
  - Files: `app/services/moderation/providers/base_provider.rb`, `app/services/moderation/providers.rb`
  - BaseProviderクラス（analyze抽象メソッド、name）
  - Providersモジュール（currentプロバイダー取得、登録機能）
  - Purpose: プロバイダー抽象化の基盤
  - _Leverage: なし（新規サービス層）_
  - _Requirements: REQ-4_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Ruby Developer specializing in design patterns | Task: Create Moderation::Providers module with BaseProvider abstract class defining analyze(attachment) interface and name method. Create Providers registry with .current method that returns provider based on Rails configuration | Restrictions: Use Strategy Pattern, raise NotImplementedError for abstract methods, support configuration via Rails.application.config.moderation.provider | Success: BaseProvider defines clear interface, Providers.current returns correct provider instance | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 2.2. AWS Rekognitionプロバイダー実装
  - Files: `app/services/moderation/providers/rekognition_provider.rb`
  - RekognitionProviderクラス（BaseProvider継承）
  - DetectModerationLabels API呼び出し、結果パース
  - Purpose: AWS Rekognitionによる画像モデレーション実装
  - _Leverage: app/services/moderation/providers/base_provider.rb_
  - _Requirements: REQ-1, REQ-4_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: AWS Developer with Ruby SDK expertise | Task: Implement RekognitionProvider extending BaseProvider, call AWS Rekognition DetectModerationLabels API, parse response into standardized result format with labels array and max_confidence score | Restrictions: Use aws-sdk-rekognition gem, handle API errors gracefully, respect configured threshold, do not store AWS credentials in code | Success: Provider correctly calls Rekognition API, returns standardized result format, handles errors appropriately | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 2.3. ModerationService実装
  - Files: `app/services/moderation/moderation_service.rb`
  - ModerationServiceクラス（moderate実行、スキップ判定、結果保存、アクション適用）
  - Purpose: モデレーション判定の統括ロジック
  - _Leverage: app/services/moderation/providers.rb, app/models/moderation_result.rb, app/models/entry.rb_
  - _Requirements: REQ-1, REQ-3_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Service Layer Developer | Task: Create ModerationService with .moderate(entry) class method that: checks if moderation is enabled for contest, calls provider.analyze, saves ModerationResult, updates Entry moderation_status based on result (approved if no violation, hidden if violation detected) | Restrictions: Handle provider errors by setting requires_review status, check contest.moderation_enabled before processing, use transaction for data integrity | Success: Service orchestrates moderation flow correctly, handles all scenarios including errors | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 2.4. サービス層テスト作成
  - Files: `spec/services/moderation/moderation_service_spec.rb`, `spec/services/moderation/providers/rekognition_provider_spec.rb`
  - ModerationServiceのモック化テスト
  - RekognitionProviderのスタブ化テスト
  - Purpose: サービス層の品質保証
  - _Leverage: spec/support/_, VCRまたはWebMock_
  - _Requirements: REQ-1, REQ-4_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Engineer | Task: Create comprehensive specs for ModerationService (mock provider) and RekognitionProvider (stub AWS API). Test violation detection, approval flow, error handling, and contest setting respect | Restrictions: Never call real AWS API in tests, use WebMock or VCR for API stubbing, test all status transitions | Success: All service specs pass, good coverage of success and error scenarios | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

## Phase 3: ジョブ・統合層

- [x] 3.1. ModerationJob実装
  - Files: `app/jobs/moderation_job.rb`
  - ModerationJobクラス（リトライ設定、エラーハンドリング）
  - Purpose: 非同期モデレーション実行
  - _Leverage: app/jobs/application_job.rb, app/services/moderation/moderation_service.rb_
  - _Requirements: REQ-1_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Background Job Developer | Task: Create ModerationJob that calls ModerationService.moderate(entry), configure retry_on for transient errors with exponential backoff (3 attempts), discard_on for DeserializationError, rescue from all errors and set entry to requires_review | Restrictions: Use queue_as :moderation, handle case where entry no longer exists, log errors appropriately | Success: Job executes moderation asynchronously, retries on failure, fails gracefully | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 3.2. Entryコールバックでジョブキュー
  - Files: `app/models/entry.rb`
  - after_createコールバックでModerationJob.perform_later呼び出し
  - Purpose: エントリー作成時に自動モデレーション開始
  - _Leverage: app/models/entry.rb, app/jobs/moderation_job.rb_
  - _Requirements: REQ-1_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Model Developer | Task: Add after_create callback to Entry model that enqueues ModerationJob.perform_later(id) only if contest has moderation enabled and photo is attached | Restrictions: Check contest.moderation_enabled? before enqueueing, do not block the create action, handle edge cases | Success: Job is enqueued after entry creation when moderation is enabled, not enqueued when disabled | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 3.3. ジョブ・統合テスト作成
  - Files: `spec/jobs/moderation_job_spec.rb`, `spec/requests/entries_spec.rb`（追加）
  - ModerationJobのキュー、実行テスト
  - エントリー作成→ジョブキューの統合テスト
  - Purpose: 非同期フローの品質保証
  - _Leverage: spec/jobs/, spec/requests/entries_spec.rb_
  - _Requirements: REQ-1_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Integration Test Engineer | Task: Create ModerationJob specs testing enqueueing, execution, retry behavior, and error handling. Add integration tests to entries_spec.rb verifying job is enqueued on entry creation when moderation enabled | Restrictions: Use ActiveJob::TestHelper, test with perform_enqueued_jobs where appropriate, verify correct arguments | Success: Job specs pass, integration tests verify end-to-end flow | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

## Phase 4: 設定・インフラ

- [x] 4.1. AWS SDK gem追加と設定
  - Files: `Gemfile`, `config/initializers/moderation.rb`, `config/credentials.yml.enc`（要手動）
  - aws-sdk-rekognition gem追加
  - モデレーション設定イニシャライザ作成
  - Purpose: AWS連携の基盤設定
  - _Leverage: Gemfile_
  - _Requirements: REQ-4_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails DevOps Developer | Task: Add aws-sdk-rekognition gem to Gemfile, create config/initializers/moderation.rb that configures Rails.application.config.moderation with provider, threshold, and enabled settings from environment variables, document credentials setup in comments | Restrictions: Use environment variables for configuration, do not commit credentials, support both development and production environments | Success: Gem installs correctly, configuration is loaded, AWS client initializes (with valid credentials) | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

## Phase 5: 管理UI

- [x] 5.1. ModerationControllerとルーティング
  - Files: `app/controllers/organizers/moderation_controller.rb`, `config/routes.rb`
  - ModerationController（index, approve, reject アクション）
  - ルーティング追加（/organizers/contests/:contest_id/moderation）
  - Purpose: 主催者向けモデレーション管理エンドポイント
  - _Leverage: app/controllers/organizers/entries_controller.rb_
  - _Requirements: REQ-2, REQ-5_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Controller Developer | Task: Create Organizers::ModerationController with index action showing entries requiring review, approve/reject actions updating entry status with audit trail in review_note. Add routes nested under contests. Ensure only contest owner can access | Restrictions: Authorize access to contest owner only, use Turbo for approve/reject actions, record reviewer and timestamp | Success: Controller actions work correctly, routes are properly nested, authorization enforced | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 5.2. モデレーションダッシュボードビュー
  - Files: `app/views/organizers/moderation/index.html.erb`, `app/views/organizers/moderation/_entry.html.erb`
  - モデレーション一覧画面（要レビューエントリー表示）
  - エントリーカード（サムネイル、検出ラベル、承認/却下ボタン）
  - Purpose: 主催者向けモデレーション管理UI
  - _Leverage: app/views/organizers/entries/_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer with Hotwire expertise | Task: Create moderation index view showing entries with requires_review or hidden status, display thumbnail, detected labels with confidence, approve/reject buttons using Turbo for inline updates. Add filtering by status | Restrictions: Use existing styling patterns, implement Turbo Frame for entry cards, show Japanese labels for status | Success: Dashboard displays entries correctly, Turbo updates work smoothly, UI is intuitive | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 5.3. コンテスト詳細にモデレーションリンク追加
  - Files: `app/views/organizers/contests/show.html.erb`
  - モデレーションダッシュボードへのナビゲーションリンク
  - 要レビュー件数バッジ表示
  - Purpose: モデレーション機能への導線
  - _Leverage: app/views/organizers/contests/show.html.erb_
  - _Requirements: REQ-5_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer | Task: Add link to moderation dashboard from contest show page, display badge showing count of entries requiring review, only show when moderation is enabled for contest | Restrictions: Follow existing navigation patterns, use Tailwind for badge styling, conditionally render based on moderation_enabled | Success: Link appears on contest page, badge shows correct count, hidden when moderation disabled | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 5.4. コントローラー・ビューテスト作成
  - Files: `spec/requests/organizers/moderation_spec.rb`
  - ModerationControllerのリクエストスペック
  - モデレーションダッシュボードのシステムテスト
  - Purpose: UI層の品質保証
  - _Leverage: spec/requests/organizers/entries_spec.rb, spec/system/organizers/_
  - _Requirements: REQ-2, REQ-5_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Engineer | Task: Create request specs for ModerationController testing authorization, index filtering, approve/reject actions. Create system specs testing dashboard navigation, entry display, approve/reject workflow with Turbo | Restrictions: Test authorization thoroughly, use Capybara for system tests, verify Turbo updates | Success: All controller and system specs pass, authorization is properly tested | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

## Phase 6: エントリー表示制御

- [x] 6.1. エントリー一覧でのフィルタリング
  - Files: `app/controllers/gallery_controller.rb`, `app/views/contests/show.html.erb`
  - 非表示エントリーを一覧から除外（approved/pendingのみ表示）
  - Purpose: 違反エントリーの非表示
  - _Leverage: app/controllers/gallery_controller.rb, app/models/entry.rb_
  - _Requirements: REQ-1_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Controller Developer | Task: Modify entries index to filter out hidden entries, show only approved and pending entries to participants. Add scope to Entry model for visible entries | Restrictions: Do not break existing pagination, organizers should still see all entries in their dashboard, add Entry.visible scope | Success: Hidden entries not shown in public listing, organizers can see all entries | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 6.2. エントリー詳細でのステータス表示
  - Files: `app/views/entries/show.html.erb`, `app/views/organizers/entries/show.html.erb`
  - 主催者向け：モデレーションステータスバッジ表示
  - 投稿者向け：自分のエントリーが非表示の場合の通知
  - Purpose: モデレーション状態の可視化
  - _Leverage: app/views/entries/show.html.erb_
  - _Requirements: REQ-2_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails View Developer | Task: Add moderation status badge to entry show page for organizers (pending/approved/hidden/requires_review with color coding). For entry owner, show notice if their entry is hidden or under review | Restrictions: Use Tailwind badge styling, show Japanese labels, only show to authorized users | Success: Status is clearly visible, appropriate messages shown to owners | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 6.3. 表示制御テスト追加
  - Files: `spec/requests/gallery_spec.rb`
  - 非表示エントリーのアクセス制御テスト
  - ステータス表示のテスト
  - Purpose: 表示制御の品質保証
  - _Leverage: spec/requests/entries_spec.rb_
  - _Requirements: REQ-1, REQ-2_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Engineer | Task: Add request specs verifying hidden entries are not shown in index, entry owners can see their own hidden entries, organizers can see all entries. Add system tests for status badge display | Restrictions: Test all user roles (guest, participant, organizer), verify authorization | Success: All visibility tests pass, authorization is properly enforced | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

## Phase 7: コンテスト設定UI

- [x] 7.1. コンテストフォームにモデレーション設定追加
  - Files: `app/views/organizers/contests/_form.html.erb`, `app/controllers/organizers/contests_controller.rb`, `app/javascript/controllers/moderation_settings_controller.js`
  - モデレーション有効/無効チェックボックス
  - 閾値設定フィールド（スライダーまたは数値入力）
  - Purpose: コンテストごとのモデレーション設定UI
  - _Leverage: app/views/organizers/contests/_form.html.erb_
  - _Requirements: REQ-3_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Form Developer | Task: Add moderation settings section to contest form with checkbox for moderation_enabled and number input for moderation_threshold (0-100). Update strong params in controller | Restrictions: Use existing form styling, add Japanese labels, validate threshold range client-side | Success: Settings are editable in form, saved correctly, displayed on contest show | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_

- [x] 7.2. コンテスト設定テスト
  - Files: `spec/requests/organizers/contests_spec.rb`
  - モデレーション設定の保存テスト
  - 設定UIのシステムテスト
  - Purpose: 設定機能の品質保証
  - _Leverage: spec/requests/organizers/contests_spec.rb_
  - _Requirements: REQ-3_
  - _Prompt: Implement the task for spec content-moderation, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Engineer | Task: Add request specs for contest moderation settings update. Add system tests for settings form interaction, validation, and persistence | Restrictions: Test default values, boundary conditions for threshold, toggle behavior | Success: All contest settings tests pass | After completing the task, mark it as [-] in progress in tasks.md, then use log-implementation tool to record details, then mark as [x] complete_
