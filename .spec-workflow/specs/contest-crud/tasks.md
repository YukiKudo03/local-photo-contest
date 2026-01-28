# Tasks Document

## Overview

コンテスト作成・管理機能の実装タスク。Contest モデル、Organizers::ContestsController、ビュー、テストを順次実装する。

---

## Phase 1: Contest モデルの実装

- [x] 1. Contest モデルのマイグレーション作成
  - File: db/migrate/20260113153739_create_contests.rb
  - contests テーブルを作成（user_id, title, description, theme, status, entry_start_at, entry_end_at, deleted_at, timestamps）
  - Purpose: コンテストデータの永続化基盤
  - _Leverage: Rails generator_
  - _Requirements: 2, 3, 5, 6, 7_

- [x] 1.1 Contest モデルの基本実装
  - File: app/models/contest.rb
  - belongs_to :user, enum :status, バリデーション、スコープを実装
  - Purpose: コンテストのビジネスロジック基盤
  - _Leverage: ApplicationRecord, User model_
  - _Requirements: 2, 3, 4_

- [x] 1.2 Contest モデルのステータス遷移メソッド実装
  - File: app/models/contest.rb
  - publish!, finish!, soft_delete!, accepting_entries?, owned_by? メソッドを実装
  - Purpose: ステータス管理ロジック
  - _Leverage: ActiveRecord_
  - _Requirements: 5, 6, 7_

- [x] 1.3 User モデルに Contest 関連付けを追加
  - File: app/models/user.rb
  - has_many :contests, dependent: :destroy を追加
  - Purpose: ユーザーとコンテストの関連付け
  - _Leverage: User model_
  - _Requirements: 2_

---

## Phase 2: ルーティングとコントローラーの実装

- [x] 2. ルーティングの設定
  - File: config/routes.rb
  - organizers 名前空間に resources :contests と member routes (publish, finish) を追加
  - Purpose: URL 構造の確立
  - _Leverage: 既存の organizers namespace_
  - _Requirements: 1, 2, 3, 4, 5, 6, 7_

- [x] 2.1 ContestsController の基本構造作成
  - File: app/controllers/organizers/contests_controller.rb
  - Organizers::BaseController を継承、before_action でコンテスト取得と所有者チェック
  - Purpose: コントローラーの基盤
  - _Leverage: Organizers::BaseController_
  - _Requirements: 1, 3_

- [x] 2.2 ContestsController の index アクション実装
  - File: app/controllers/organizers/contests_controller.rb
  - 現在のユーザーのコンテスト一覧取得、ステータスフィルタリング
  - Purpose: コンテスト一覧機能
  - _Leverage: Contest scopes_
  - _Requirements: 1_

- [x] 2.3 ContestsController の show アクション実装
  - File: app/controllers/organizers/contests_controller.rb
  - コンテスト詳細表示
  - Purpose: コンテスト詳細機能
  - _Leverage: Contest model_
  - _Requirements: 4_

- [x] 2.4 ContestsController の new/create アクション実装
  - File: app/controllers/organizers/contests_controller.rb
  - 新規作成フォーム表示と作成処理
  - Purpose: コンテスト作成機能
  - _Leverage: Contest model, Strong Parameters_
  - _Requirements: 2_

- [x] 2.5 ContestsController の edit/update アクション実装
  - File: app/controllers/organizers/contests_controller.rb
  - 編集フォーム表示と更新処理
  - Purpose: コンテスト編集機能
  - _Leverage: Contest model_
  - _Requirements: 3_

- [x] 2.6 ContestsController の destroy アクション実装
  - File: app/controllers/organizers/contests_controller.rb
  - 論理削除処理
  - Purpose: コンテスト削除機能
  - _Leverage: Contest#soft_delete!_
  - _Requirements: 7_

- [x] 2.7 ContestsController の publish/finish アクション実装
  - File: app/controllers/organizers/contests_controller.rb
  - 公開・終了ステータス変更処理
  - Purpose: ステータス変更機能
  - _Leverage: Contest#publish!, Contest#finish!_
  - _Requirements: 5, 6_

---

## Phase 3: ビューの実装

- [x] 3. コンテスト一覧ビューの作成
  - File: app/views/organizers/contests/index.html.erb
  - ステータスフィルタータブ、コンテストカードグリッド、新規作成ボタン、空状態表示
  - Purpose: コンテスト一覧 UI
  - _Leverage: Tailwind CSS, shared partials_
  - _Requirements: 1_

- [x] 3.1 コンテスト詳細ビューの作成
  - File: app/views/organizers/contests/show.html.erb
  - コンテスト情報表示、ステータスバッジ、アクションボタン
  - Purpose: コンテスト詳細 UI
  - _Leverage: Tailwind CSS_
  - _Requirements: 4_

- [x] 3.2 コンテストフォームパーシャルの作成
  - File: app/views/organizers/contests/_form.html.erb
  - タイトル、説明、テーマ、期間入力フォーム
  - Purpose: 共通フォーム UI
  - _Leverage: Rails form helpers, Tailwind CSS_
  - _Requirements: 2, 3_

- [x] 3.3 新規作成ビューの作成
  - File: app/views/organizers/contests/new.html.erb
  - 新規作成フォームのラッパー
  - Purpose: 新規作成 UI
  - _Leverage: _form partial_
  - _Requirements: 2_

- [x] 3.4 編集ビューの作成
  - File: app/views/organizers/contests/edit.html.erb
  - 編集フォームのラッパー
  - Purpose: 編集 UI
  - _Leverage: _form partial_
  - _Requirements: 3_

- [x] 3.5 サイドバーにコンテスト一覧リンクを追加
  - File: app/views/shared/_sidebar.html.erb
  - コンテスト一覧へのナビゲーションリンクを追加
  - Purpose: ナビゲーション改善
  - _Leverage: 既存サイドバー構造_
  - _Requirements: 1_

---

## Phase 4: テストの実装

- [x] 4. Contest ファクトリの作成
  - File: spec/factories/contests.rb
  - Contest ファクトリと traits (draft, published, finished) を定義
  - Purpose: テストデータ生成
  - _Leverage: FactoryBot_
  - _Requirements: 全体_

- [x] 4.1 Contest モデルのユニットテスト
  - File: spec/models/contest_spec.rb
  - バリデーション、enum、スコープ、インスタンスメソッドのテスト
  - Purpose: モデルの信頼性確保
  - _Leverage: RSpec, Shoulda Matchers_
  - _Requirements: 2, 5, 6, 7_

- [x] 4.2 ContestsController のリクエストテスト
  - File: spec/requests/organizers/contests_spec.rb
  - CRUD 各アクションのテスト、認証・権限テスト
  - Purpose: API の信頼性確保
  - _Leverage: RSpec request specs_
  - _Requirements: 1, 2, 3, 4, 5, 6, 7_

- [x] 4.3 コンテスト管理のシステムテスト
  - File: spec/system/organizers/contest_management_spec.rb
  - 作成・編集・公開・終了フローの E2E テスト
  - Purpose: ユーザーフローの検証
  - _Leverage: RSpec + Capybara_
  - _Requirements: 1, 2, 3, 5, 6_

---

## Phase 5: 日本語化と仕上げ

- [x] 5. Contest 関連の日本語ロケール追加
  - File: config/locales/contests.ja.yml
  - モデル名、属性名、エラーメッセージ、フラッシュメッセージの日本語化
  - Purpose: 完全な日本語 UI
  - _Leverage: Rails I18n_
  - _Requirements: Non-Functional (Usability)_

- [x] 5.1 ダッシュボードにコンテスト統計を追加
  - File: app/views/organizers/dashboards/show.html.erb
  - コンテスト数の表示を実データに更新
  - Purpose: ダッシュボード改善
  - _Leverage: Contest model_
  - _Requirements: 1_
