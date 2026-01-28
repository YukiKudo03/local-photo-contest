# Tasks Document

## Overview
運営組織アカウント認証システムの実装タスク。Devise + Rails 7.1 による認証基盤と利用規約同意機能を構築する。

---

## Phase 1: Rails プロジェクト初期化

- [x] 1. Rails 7.1 アプリケーションの初期化
  - File: Gemfile, config/application.rb
  - Rails 7.1 新規プロジェクトを作成し、基本的な設定を行う
  - Purpose: プロジェクトの基盤を確立
  - _Leverage: なし（新規作成）_
  - _Requirements: 全体の前提条件_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Initialize Rails 7.1 application with SQLite for development. Run `rails new local-photo-contest --database=sqlite3 --css=tailwind --javascript=importmap`. Configure application.rb for Japanese locale and timezone. | Restrictions: Do not add unnecessary gems yet, keep minimal setup | Success: Rails server starts without errors, default page loads | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 1.1 Gemfile に必要な gem を追加
  - File: Gemfile
  - Devise, RSpec, FactoryBot, その他必要な gem を追加
  - Purpose: 認証とテストに必要な依存関係を追加
  - _Leverage: なし_
  - _Requirements: 1, 2, 3, 4, 5, 6, 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add gems to Gemfile: devise, rspec-rails, factory_bot_rails, capybara, shoulda-matchers, rubocop, brakeman. Run bundle install. | Restrictions: Only add gems specified, do not modify other files | Success: bundle install completes without errors | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

---

## Phase 2: Devise セットアップと User モデル

- [x] 2. Devise のインストールと初期設定
  - File: config/initializers/devise.rb, config/locales/devise.ja.yml
  - Devise をインストールし、日本語化と基本設定を行う
  - Purpose: 認証機能の基盤を確立
  - _Leverage: devise gem_
  - _Requirements: 1, 2, 3, 4, 6_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in authentication | Task: Run `rails generate devise:install`. Configure devise.rb with: mailer_sender, password_length (minimum: 8), lock_strategy (:failed_attempts), maximum_attempts (5), unlock_in (30.minutes), confirm_within (24.hours), reset_password_within (6.hours), remember_for (2.weeks), timeout_in (24.hours). Add Japanese locale file for Devise. | Restrictions: Follow exact configuration values from requirements | Success: Devise initializer configured, Japanese messages work | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 2.1 User モデルの生成とマイグレーション
  - File: app/models/user.rb, db/migrate/XXXXXX_devise_create_users.rb
  - Devise User モデルを生成し、role カラムを追加
  - Purpose: ユーザーデータの永続化基盤を確立
  - _Leverage: devise gem, ActiveRecord_
  - _Requirements: 1, 2, 5_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Run `rails generate devise User`. Add role column (integer, default: 0) to migration. Include all Devise modules: database_authenticatable, registerable, recoverable, rememberable, validatable, confirmable, lockable, timeoutable, trackable. Run migration. | Restrictions: Follow exact schema from design.md | Success: User table created with all columns, migration runs without errors | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 2.2 User モデルのバリデーションと enum 設定
  - File: app/models/user.rb
  - role enum と organizer? メソッドを実装
  - Purpose: 権限管理の基盤を確立
  - _Leverage: ActiveRecord enum_
  - _Requirements: 5_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: In User model, add enum role with participant (0), organizer (1), admin (2). Add organizer? method that returns true for organizer or admin roles. Add validations for email presence/uniqueness and role presence. | Restrictions: Do not add terms acceptance methods yet | Success: User.roles returns hash, user.organizer? works correctly | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

---

## Phase 3: 利用規約モデルの実装

- [x] 3. TermsOfService モデルの作成
  - File: app/models/terms_of_service.rb, db/migrate/XXXXXX_create_terms_of_services.rb
  - 利用規約のバージョン管理モデルを作成
  - Purpose: 利用規約のバージョン管理を実現
  - _Leverage: ActiveRecord_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Generate TermsOfService model with: version (string, not null, unique), content (text, not null), published_at (datetime, not null). Add indexes. Add scopes: published, by_version. Add class method self.current. Add has_many :terms_acceptances with dependent: :restrict_with_error. | Restrictions: Follow exact schema from design.md | Success: TermsOfService.current returns latest published terms | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 3.1 TermsAcceptance モデルの作成
  - File: app/models/terms_acceptance.rb, db/migrate/XXXXXX_create_terms_acceptances.rb
  - 利用規約同意記録モデルを作成
  - Purpose: 同意記録の永続化（日時、IP、バージョン）
  - _Leverage: ActiveRecord_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Generate TermsAcceptance model with: user_id (references, not null, foreign_key), terms_of_service_id (references, not null, foreign_key), accepted_at (datetime, not null), ip_address (string, not null). Add composite unique index on [user_id, terms_of_service_id]. Add belongs_to associations. Add validations and scopes. | Restrictions: Follow exact schema from design.md | Success: TermsAcceptance records can be created with all required fields | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 3.2 User モデルに利用規約関連メソッドを追加
  - File: app/models/user.rb
  - has_many :terms_acceptances と accepted_current_terms?, accept_terms! メソッドを追加
  - Purpose: ユーザーの利用規約同意状態管理
  - _Leverage: TermsOfService, TermsAcceptance models_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add to User model: has_many :terms_acceptances (dependent: :destroy). Add accepted_current_terms? method that checks if user has accepted current terms. Add accept_terms!(terms_of_service, ip_address) method that creates acceptance record. | Restrictions: Follow exact implementation from design.md | Success: user.accepted_current_terms? returns correct boolean, user.accept_terms! creates record | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

---

## Phase 4: コントローラーとルーティング

- [x] 4. Organizers 名前空間の基本コントローラー作成
  - File: app/controllers/organizers/base_controller.rb
  - 運営者エリアの共通認証フィルターを持つ基底コントローラー
  - Purpose: 運営者エリアのアクセス制御基盤
  - _Leverage: Devise helpers_
  - _Requirements: 5_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create Organizers::BaseController inheriting from ApplicationController. Add before_action :authenticate_user! and before_action :require_organizer!. Implement require_organizer! method that redirects non-organizers with 403. | Restrictions: Do not add terms acceptance check yet | Success: Non-authenticated users redirected to login, non-organizers see 403 | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.1 TermsAcceptable Concern の作成
  - File: app/controllers/concerns/terms_acceptable.rb
  - 利用規約同意チェックロジックを Concern として実装
  - Purpose: 利用規約同意状態の検証とリダイレクト
  - _Leverage: TermsOfService, TermsAcceptance models_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create TermsAcceptable concern with: require_terms_acceptance! (before_action filter), current_terms (helper), accepted_current_terms? (helper). require_terms_acceptance! should redirect to terms acceptance page if user hasn't accepted current terms. Skip check for TermsAcceptancesController. | Restrictions: Follow design.md patterns | Success: Users without terms acceptance are redirected to /organizers/terms/new | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.2 Organizers::BaseController に TermsAcceptable を追加
  - File: app/controllers/organizers/base_controller.rb
  - TermsAcceptable concern を include し、before_action を追加
  - Purpose: 運営者エリア全体で利用規約同意を必須化
  - _Leverage: TermsAcceptable concern_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Include TermsAcceptable concern in Organizers::BaseController. Add before_action :require_terms_acceptance! after authentication checks. | Restrictions: Ensure proper filter order (authenticate -> organizer check -> terms check) | Success: Organizers without terms acceptance redirected before accessing any organizer page | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.3 Organizers::TermsAcceptancesController の作成
  - File: app/controllers/organizers/terms_acceptances_controller.rb
  - 利用規約表示と同意記録作成のコントローラー
  - Purpose: 利用規約同意 UI のバックエンド
  - _Leverage: TermsOfService, User#accept_terms!_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create Organizers::TermsAcceptancesController inheriting from Organizers::BaseController. Skip require_terms_acceptance! for this controller. Add new action (shows current terms). Add create action (calls current_user.accept_terms! with request.remote_ip, redirects to dashboard). | Restrictions: Record IP address from request.remote_ip | Success: GET /organizers/terms/new shows terms, POST /organizers/terms creates acceptance record with IP | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.4 Organizers::DashboardController の作成
  - File: app/controllers/organizers/dashboard_controller.rb
  - 運営者ダッシュボードのコントローラー
  - Purpose: ログイン後のランディングページ
  - _Leverage: Organizers::BaseController_
  - _Requirements: 2_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create Organizers::DashboardController inheriting from Organizers::BaseController. Add index action. | Restrictions: Keep simple, just render view | Success: GET /organizers/dashboard renders dashboard view | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.5 カスタム SessionsController の作成
  - File: app/controllers/organizers/sessions_controller.rb
  - ログイン/ログアウトのリダイレクト先をカスタマイズ
  - Purpose: ログイン後に利用規約チェックを経由してダッシュボードへ
  - _Leverage: Devise::SessionsController_
  - _Requirements: 2, 4_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in Devise | Task: Create Organizers::SessionsController inheriting from Devise::SessionsController. Override after_sign_in_path_for to redirect to organizers_dashboard_path (terms check handled by concern). Override after_sign_out_path_for to redirect to root. | Restrictions: Follow Devise conventions, use super where possible | Success: Login redirects to dashboard, logout redirects to root | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.5.1 カスタム RegistrationsController の作成
  - File: app/controllers/organizers/registrations_controller.rb
  - 登録後のリダイレクト先をカスタマイズ
  - Purpose: 登録成功時に確認メール送信通知を表示
  - _Leverage: Devise::RegistrationsController_
  - _Requirements: 1_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in Devise | Task: Create Organizers::RegistrationsController inheriting from Devise::RegistrationsController. Override after_inactive_sign_up_path_for to redirect to root with flash notice about confirmation email. | Restrictions: Follow Devise conventions | Success: Registration shows confirmation email notice | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.5.2 カスタム PasswordsController の作成
  - File: app/controllers/organizers/passwords_controller.rb
  - パスワードリセット後のリダイレクト先をカスタマイズ
  - Purpose: パスワードリセット成功時にログイン画面へ
  - _Leverage: Devise::PasswordsController_
  - _Requirements: 3_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in Devise | Task: Create Organizers::PasswordsController inheriting from Devise::PasswordsController. Override after_resetting_password_path_for to redirect to login page. | Restrictions: Follow Devise conventions | Success: Password reset redirects to login | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.5.3 カスタム ConfirmationsController の作成
  - File: app/controllers/organizers/confirmations_controller.rb
  - メール確認後のリダイレクト先をカスタマイズ
  - Purpose: メール確認成功時にログイン画面へ
  - _Leverage: Devise::ConfirmationsController_
  - _Requirements: 1_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in Devise | Task: Create Organizers::ConfirmationsController inheriting from Devise::ConfirmationsController. Override after_confirmation_path_for to redirect to login page with success notice. | Restrictions: Follow Devise conventions | Success: Email confirmation redirects to login with notice | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 4.6 ルーティングの設定
  - File: config/routes.rb
  - Devise routes と運営者名前空間のルーティングを設定
  - Purpose: URL 構造の確立
  - _Leverage: devise_for, namespace_
  - _Requirements: 1, 2, 3, 4, 5, 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Configure routes.rb with: devise_for :users with path 'organizers' and custom controllers. Add namespace :organizers with resources :terms_acceptances (only: [:new, :create]) and resource :dashboard (only: [:show]). Set root to public home. | Restrictions: Use exact paths from design.md (/organizers/sign_in, /organizers/terms/new, etc.) | Success: rake routes shows all expected paths | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

---

## Phase 5: ビューの実装

- [x] 5. Devise ビューの生成
  - File: app/views/devise/ (generator creates files)
  - Devise 標準ビューを生成
  - Purpose: 認証 UI の基盤を作成
  - _Leverage: devise:views generator_
  - _Requirements: 1, 2, 3, 4_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Run `rails generate devise:views` to generate all Devise view templates. | Restrictions: Only run generator, do not customize yet | Success: Devise views generated in app/views/devise/ | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 5.0.1 ログインフォームの日本語化
  - File: app/views/devise/sessions/new.html.erb
  - ログインフォームを日本語化
  - Purpose: ログイン UI の日本語化
  - _Leverage: Devise sessions view_
  - _Requirements: 2_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Customize sessions/new.html.erb with Japanese labels: "メールアドレス", "パスワード", "ログイン状態を保持する", "ログイン" button. Add link to password reset. | Restrictions: Keep styling minimal with Tailwind | Success: Login form displays in Japanese | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 5.0.2 新規登録フォームの日本語化
  - File: app/views/devise/registrations/new.html.erb
  - 新規登録フォームを日本語化
  - Purpose: 新規登録 UI の日本語化
  - _Leverage: Devise registrations view_
  - _Requirements: 1_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Customize registrations/new.html.erb with Japanese labels: "メールアドレス", "パスワード（8文字以上）", "パスワード（確認）", "登録" button. Add link to login page. | Restrictions: Keep styling minimal with Tailwind | Success: Registration form displays in Japanese | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 5.0.3 パスワードリセットフォームの日本語化
  - File: app/views/devise/passwords/new.html.erb, app/views/devise/passwords/edit.html.erb
  - パスワードリセット関連フォームを日本語化
  - Purpose: パスワードリセット UI の日本語化
  - _Leverage: Devise passwords views_
  - _Requirements: 3_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Customize passwords/new.html.erb with "メールアドレス", "パスワードリセットメールを送信" button. Customize passwords/edit.html.erb with "新しいパスワード", "新しいパスワード（確認）", "パスワードを変更" button. | Restrictions: Keep styling minimal with Tailwind | Success: Password reset forms display in Japanese | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 5.0.4 メール確認再送フォームの日本語化
  - File: app/views/devise/confirmations/new.html.erb
  - メール確認再送フォームを日本語化
  - Purpose: 確認メール再送 UI の日本語化
  - _Leverage: Devise confirmations view_
  - _Requirements: 1_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Customize confirmations/new.html.erb with Japanese labels: "メールアドレス", "確認メールを再送信" button. | Restrictions: Keep styling minimal with Tailwind | Success: Confirmation resend form displays in Japanese | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 5.1 利用規約同意画面の作成
  - File: app/views/organizers/terms_acceptances/new.html.erb
  - 利用規約表示と同意ボタンのビュー
  - Purpose: 利用規約同意 UI
  - _Leverage: TermsOfService#content_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create terms acceptance view showing: title "利用規約", terms content (@terms.content), checkbox for agreement, "同意する" submit button, "同意しない（ログアウト）" link. Form posts to organizers_terms_acceptances_path. | Restrictions: User must check agreement checkbox before submitting | Success: Terms page displays content and has working agree/decline options | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 5.2 運営者ダッシュボード画面の作成
  - File: app/views/organizers/dashboards/show.html.erb
  - ダッシュボードのランディングページ
  - Purpose: ログイン成功後の表示画面
  - _Leverage: current_user_
  - _Requirements: 2_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create dashboard view with: welcome message including current_user.email, logout link (using Devise helper), placeholder for future contest management features. | Restrictions: Keep simple, this is just a landing page for now | Success: Dashboard shows user email and working logout link | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 5.3 共通レイアウトとフラッシュメッセージ
  - File: app/views/layouts/application.html.erb, app/views/shared/_flash.html.erb
  - アプリケーションレイアウトとフラッシュメッセージ表示
  - Purpose: 統一された UI 体験
  - _Leverage: Rails flash messages_
  - _Requirements: 1, 2, 3, 4_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Update application layout with: proper HTML5 structure, flash message partial rendering, yield for content. Create flash partial that displays notice (green) and alert (red) messages. Add basic Tailwind styling. | Restrictions: Use Tailwind classes for styling | Success: Flash messages appear styled correctly after login/logout | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

---

## Phase 6: Stimulus コントローラー

- [x] 6. フォームバリデーション Stimulus コントローラーの作成
  - File: app/javascript/controllers/form_validation_controller.js
  - リアルタイムフォームバリデーション UI
  - Purpose: ユーザビリティ向上
  - _Leverage: Stimulus framework_
  - _Requirements: Non-Functional (Usability)_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: JavaScript Developer | Task: Create Stimulus controller for form validation: validateEmail (check email format), validatePassword (check minimum 8 chars, show strength indicator), validatePasswordConfirmation (check match). Show validation messages in real-time as user types. | Restrictions: Use Stimulus conventions, no external libraries | Success: Form fields show validation feedback in real-time | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

---

## Phase 7: テストの実装

- [x] 7. RSpec のインストールと基本設定
  - File: spec/rails_helper.rb, spec/spec_helper.rb
  - RSpec をインストールし、基本設定を行う
  - Purpose: テスト基盤の確立
  - _Leverage: rspec-rails gem_
  - _Requirements: 全体_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Run `rails generate rspec:install`. Configure rails_helper with basic settings. | Restrictions: Only basic RSpec setup, no additional configurations yet | Success: `bundle exec rspec` runs without errors (0 examples) | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.0.1 テストヘルパーの設定
  - File: spec/support/devise.rb, spec/support/shoulda_matchers.rb
  - Devise テストヘルパーと Shoulda Matchers の設定
  - Purpose: テストヘルパーの有効化
  - _Leverage: devise, shoulda-matchers gems_
  - _Requirements: 全体_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create spec/support/devise.rb with Devise test helpers configuration. Create spec/support/shoulda_matchers.rb with Shoulda Matchers configuration for Rails. Update rails_helper to require support files. | Restrictions: Follow gem documentation | Success: Devise sign_in helper available in tests, Shoulda matchers work | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.0.2 FactoryBot ファクトリの作成
  - File: spec/factories/users.rb, spec/factories/terms_of_services.rb, spec/factories/terms_acceptances.rb
  - テスト用ファクトリ定義
  - Purpose: テストデータ生成の基盤
  - _Leverage: factory_bot_rails gem_
  - _Requirements: 全体_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create User factory with traits (:organizer, :admin, :confirmed). Create TermsOfService factory with trait (:current). Create TermsAcceptance factory. Configure FactoryBot in rails_helper. | Restrictions: Follow FactoryBot best practices | Success: FactoryBot.create(:user, :organizer, :confirmed) works | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.1 User モデルのユニットテスト
  - File: spec/models/user_spec.rb
  - User モデルのバリデーションと権限メソッドのテスト
  - Purpose: モデルの信頼性確保
  - _Leverage: RSpec, Shoulda Matchers_
  - _Requirements: 1, 2, 5, 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create User model spec testing: email presence/uniqueness validation, password length validation, role enum, organizer? method (true for organizer/admin, false for participant), accepted_current_terms? method, accept_terms! method. | Restrictions: Follow test examples from design.md | Success: All User model tests pass | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.2 TermsOfService と TermsAcceptance モデルのテスト
  - File: spec/models/terms_of_service_spec.rb, spec/models/terms_acceptance_spec.rb
  - 利用規約関連モデルのテスト
  - Purpose: 利用規約機能の信頼性確保
  - _Leverage: RSpec, Shoulda Matchers_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create model specs: TermsOfService (validations, self.current scope, associations), TermsAcceptance (validations including composite uniqueness, associations, scopes). | Restrictions: Follow test examples from design.md | Success: All terms model tests pass | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.3 認証フローの統合テスト
  - File: spec/requests/organizers/sessions_spec.rb, spec/requests/organizers/registrations_spec.rb
  - ログイン・登録フローのリクエストテスト
  - Purpose: 認証フローの検証
  - _Leverage: RSpec request specs, Devise test helpers_
  - _Requirements: 1, 2, 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create request specs for: login success (redirects to terms or dashboard), login failure (shows error), registration success (sends confirmation email), logout (clears session). Test terms redirect behavior. | Restrictions: Follow test examples from design.md | Success: All authentication request tests pass | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.4 利用規約フローの統合テスト
  - File: spec/requests/organizers/terms_acceptances_spec.rb
  - 利用規約同意フローのリクエストテスト
  - Purpose: 利用規約機能の検証
  - _Leverage: RSpec request specs_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create request specs for TermsAcceptancesController: new action shows terms, create action records acceptance with IP address, redirect to dashboard after acceptance. Test IP address is captured correctly. | Restrictions: Follow test examples from design.md | Success: All terms acceptance request tests pass | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.5 認証フローのシステムテスト
  - File: spec/system/organizer_authentication_spec.rb
  - 登録・ログイン・ログアウトのE2Eテスト
  - Purpose: 認証ユーザージャーニーの検証
  - _Leverage: RSpec + Capybara_
  - _Requirements: 1, 2, 4_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create system spec for authentication: signup form submission, login with valid credentials, logout functionality. | Restrictions: Follow test examples from design.md | Success: Authentication system tests pass | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.5.1 パスワードリセットのシステムテスト
  - File: spec/system/password_reset_spec.rb
  - パスワードリセットフローのE2Eテスト
  - Purpose: パスワードリセットジャーニーの検証
  - _Leverage: RSpec + Capybara_
  - _Requirements: 3_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create system spec for password reset: request reset email form, password change form. | Restrictions: Follow test examples from design.md | Success: Password reset system tests pass | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 7.5.2 利用規約同意のシステムテスト
  - File: spec/system/terms_acceptance_spec.rb
  - 利用規約同意フローのE2Eテスト
  - Purpose: 利用規約ジャーニーの検証
  - _Leverage: RSpec + Capybara_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: QA Engineer | Task: Create system spec for terms acceptance: first login requires terms, accept terms redirects to dashboard, decline terms shows logout option, terms update requires re-acceptance. | Restrictions: Follow test examples from design.md | Success: Terms acceptance system tests pass | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

---

## Phase 8: シードデータと仕上げ

- [x] 8. シードデータの作成
  - File: db/seeds.rb
  - 開発用の初期データ（利用規約、テストユーザー）
  - Purpose: 開発・テスト環境のセットアップ
  - _Leverage: ActiveRecord_
  - _Requirements: 7_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create seeds.rb with: initial TermsOfService (version "1.0", sample content, published_at: Time.current), test organizer user (organizer@example.com, confirmed). | Restrictions: Use realistic sample data | Success: rake db:seed creates terms and test user | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 8.1 日本語ロケールファイルの整備
  - File: config/locales/ja.yml
  - アプリケーション全体の日本語メッセージ
  - Purpose: 完全な日本語 UI
  - _Leverage: Rails I18n_
  - _Requirements: Non-Functional (Usability)_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create/update ja.yml with Japanese translations for: model names, attribute names, error messages, flash messages, view labels, button text. Ensure all user-facing text is in Japanese. | Restrictions: Cover all strings from views and controllers | Success: Application displays entirely in Japanese | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_

- [x] 8.2 セキュリティ設定の確認
  - File: config/environments/production.rb, config/initializers/devise.rb
  - 本番環境向けセキュリティ設定の確認と調整
  - Purpose: セキュリティ要件の充足
  - _Leverage: Rails security features_
  - _Requirements: Non-Functional (Security)_
  - _Prompt: Implement the task for spec contest-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Security Engineer | Task: Review and configure: force_ssl in production, secure session cookies, CSRF protection, Devise bcrypt cost (12+), session fixation protection (reset session on sign_in). Run Brakeman security scan and address any warnings. | Restrictions: Follow OWASP guidelines | Success: Brakeman reports no high-severity issues | After completion: Mark task [-] as in-progress in tasks.md before starting, use log-implementation tool to record what was done, then mark [x] as complete_
