# Tasks Document

## Overview

写真投稿機能の実装タスク。Entry モデル、参加者向けコントローラー、運営者向けコントローラー、ビュー、テストを順次実装する。

---

## Phase 1: Entry モデルの実装

- [x] 1. Entry モデルのマイグレーション作成
  - File: db/migrate/20260113232149_create_entries.rb
  - entries テーブルを作成（user_id, contest_id, title, description, location, taken_at, timestamps）
  - Purpose: 応募データの永続化基盤
  - _Leverage: Rails generator_
  - _Requirements: 3_

- [x] 1.1 Entry モデルの基本実装
  - File: app/models/entry.rb
  - belongs_to :user, :contest, has_one_attached :photo, バリデーション、スコープを実装
  - Purpose: 応募のビジネスロジック基盤
  - _Leverage: ApplicationRecord, Active Storage_
  - _Requirements: 3, 6, 7_

- [x] 1.2 Contest モデルに Entry 関連付けを追加
  - File: app/models/contest.rb
  - has_many :entries, dependent: :destroy を追加
  - Purpose: コンテストと応募の関連付け
  - _Leverage: Contest model_
  - _Requirements: 8_

- [x] 1.3 User モデルに Entry 関連付けを追加
  - File: app/models/user.rb
  - has_many :entries, dependent: :destroy を追加
  - Purpose: ユーザーと応募の関連付け
  - _Leverage: User model_
  - _Requirements: 4_

---

## Phase 2: 参加者向けルーティングとコントローラーの実装

- [x] 2. 参加者向けルーティングの設定
  - File: config/routes.rb
  - contests (index, show), entries (CRUD), my/entries を追加
  - Purpose: 参加者向け URL 構造の確立
  - _Leverage: 既存のルーティング_
  - _Requirements: 1, 2, 3, 4, 5, 6, 7_

- [x] 2.1 ContestsController（参加者向け）の作成
  - File: app/controllers/contests_controller.rb
  - index（公開中コンテスト一覧）、show（詳細）アクション
  - Purpose: 参加者向けコンテスト表示
  - _Leverage: ApplicationController_
  - _Requirements: 1, 2_

- [x] 2.2 EntriesController の基本構造作成
  - File: app/controllers/entries_controller.rb
  - before_action で認証、応募取得、所有者チェック
  - Purpose: 応募コントローラーの基盤
  - _Leverage: ApplicationController, Devise_
  - _Requirements: 3, 6, 7_

- [x] 2.3 EntriesController の new/create アクション実装
  - File: app/controllers/entries_controller.rb
  - 応募フォーム表示と作成処理
  - Purpose: 応募作成機能
  - _Leverage: Entry model, Active Storage_
  - _Requirements: 3_

- [x] 2.4 EntriesController の show アクション実装
  - File: app/controllers/entries_controller.rb
  - 応募詳細表示
  - Purpose: 応募詳細機能
  - _Leverage: Entry model_
  - _Requirements: 5_

- [x] 2.5 EntriesController の edit/update アクション実装
  - File: app/controllers/entries_controller.rb
  - 編集フォーム表示と更新処理
  - Purpose: 応募編集機能
  - _Leverage: Entry model_
  - _Requirements: 6_

- [x] 2.6 EntriesController の destroy アクション実装
  - File: app/controllers/entries_controller.rb
  - 応募削除処理
  - Purpose: 応募削除機能
  - _Leverage: Entry model_
  - _Requirements: 7_

- [x] 2.7 My::EntriesController の作成
  - File: app/controllers/my/entries_controller.rb
  - 自分の応募一覧表示
  - Purpose: マイ応募機能
  - _Leverage: ApplicationController_
  - _Requirements: 4_

---

## Phase 3: 運営者向け応募管理の実装

- [x] 3. 運営者向けルーティングの更新
  - File: config/routes.rb
  - organizers/contests/:contest_id/entries を追加
  - Purpose: 運営者向け URL 構造
  - _Leverage: 既存の organizers namespace_
  - _Requirements: 8_

- [x] 3.1 Organizers::EntriesController の作成
  - File: app/controllers/organizers/entries_controller.rb
  - index（応募一覧）、show（詳細）アクション
  - Purpose: 運営者向け応募管理
  - _Leverage: Organizers::BaseController_
  - _Requirements: 8_

---

## Phase 4: 参加者向けビューの実装

- [x] 4. コンテスト一覧ビュー（参加者向け）の作成
  - File: app/views/contests/index.html.erb
  - 公開中コンテストのカードグリッド、空状態表示
  - Purpose: 参加者向けコンテスト一覧 UI
  - _Leverage: Tailwind CSS_
  - _Requirements: 1_

- [x] 4.1 コンテスト詳細ビュー（参加者向け）の作成
  - File: app/views/contests/show.html.erb
  - コンテスト情報、応募ボタン、期間外メッセージ
  - Purpose: 参加者向けコンテスト詳細 UI
  - _Leverage: Tailwind CSS_
  - _Requirements: 2_

- [x] 4.2 応募フォームパーシャルの作成
  - File: app/views/entries/_form.html.erb
  - 写真アップロード、タイトル、説明、撮影情報入力
  - Purpose: 共通応募フォーム UI
  - _Leverage: Rails form helpers, Tailwind CSS_
  - _Requirements: 3, 6_

- [x] 4.3 応募作成ビューの作成
  - File: app/views/entries/new.html.erb
  - 応募フォームのラッパー
  - Purpose: 応募作成 UI
  - _Leverage: _form partial_
  - _Requirements: 3_

- [x] 4.4 応募詳細ビューの作成
  - File: app/views/entries/show.html.erb
  - 写真、タイトル、説明、撮影情報、編集・削除ボタン
  - Purpose: 応募詳細 UI
  - _Leverage: Tailwind CSS_
  - _Requirements: 5_

- [x] 4.5 応募編集ビューの作成
  - File: app/views/entries/edit.html.erb
  - 編集フォームのラッパー
  - Purpose: 応募編集 UI
  - _Leverage: _form partial_
  - _Requirements: 6_

- [x] 4.6 マイ応募一覧ビューの作成
  - File: app/views/my/entries/index.html.erb
  - 自分の応募作品グリッド、空状態表示
  - Purpose: マイ応募一覧 UI
  - _Leverage: Tailwind CSS_
  - _Requirements: 4_

---

## Phase 5: 運営者向けビューの実装

- [x] 5. 運営者向け応募一覧ビューの作成
  - File: app/views/organizers/entries/index.html.erb
  - 応募一覧テーブル、サムネイル、応募者情報
  - Purpose: 運営者向け応募一覧 UI
  - _Leverage: Tailwind CSS_
  - _Requirements: 8_

- [x] 5.1 運営者向け応募詳細ビューの作成
  - File: app/views/organizers/entries/show.html.erb
  - 写真、応募情報、応募者情報
  - Purpose: 運営者向け応募詳細 UI
  - _Leverage: Tailwind CSS_
  - _Requirements: 8_

- [x] 5.2 コンテスト詳細画面に応募タブを追加
  - File: app/views/organizers/contests/show.html.erb
  - 応募一覧へのリンクタブを追加
  - Purpose: ナビゲーション改善
  - _Leverage: 既存のコンテスト詳細画面_
  - _Requirements: 8_

---

## Phase 6: ナビゲーションとレイアウトの更新

- [x] 6. ヘッダーに参加者向けナビゲーションを追加
  - File: app/views/shared/_header.html.erb
  - コンテスト一覧、マイ応募へのリンク
  - Purpose: ナビゲーション改善
  - _Leverage: 既存ヘッダー_
  - _Requirements: 1, 4_

- [x] 6.1 サイドバーに応募管理リンクを追加
  - File: app/views/shared/_sidebar.html.erb
  - 「応募管理」セクションを追加
  - Purpose: 運営者向けナビゲーション改善
  - _Leverage: 既存サイドバー_
  - _Requirements: 8_

---

## Phase 7: テストの実装

- [x] 7. Entry ファクトリの作成
  - File: spec/factories/entries.rb
  - Entry ファクトリと traits を定義
  - Purpose: テストデータ生成
  - _Leverage: FactoryBot_
  - _Requirements: 全体_

- [x] 7.1 Entry モデルのユニットテスト
  - File: spec/models/entry_spec.rb
  - バリデーション、スコープ、インスタンスメソッドのテスト
  - Purpose: モデルの信頼性確保
  - _Leverage: RSpec, Shoulda Matchers_
  - _Requirements: 3, 6, 7_

- [x] 7.2 EntriesController のリクエストテスト
  - File: spec/requests/entries_spec.rb
  - CRUD 各アクションのテスト、認証・権限テスト
  - Purpose: コントローラーの信頼性確保
  - _Leverage: RSpec request specs_
  - _Requirements: 3, 5, 6, 7_

- [x] 7.3 ContestsController のリクエストテスト
  - File: spec/requests/contests_spec.rb
  - 一覧・詳細のテスト
  - Purpose: コントローラーの信頼性確保
  - _Leverage: RSpec request specs_
  - _Requirements: 1, 2_

- [x] 7.4 Organizers::EntriesController のリクエストテスト
  - File: spec/requests/organizers/entries_spec.rb
  - 一覧・詳細のテスト、権限テスト
  - Purpose: コントローラーの信頼性確保
  - _Leverage: RSpec request specs_
  - _Requirements: 8_

---

## Phase 8: 日本語化と仕上げ

- [x] 8. Entry 関連の日本語ロケール追加
  - File: config/locales/entries.ja.yml
  - モデル名、属性名、エラーメッセージの日本語化
  - Purpose: 完全な日本語 UI
  - _Leverage: Rails I18n_
  - _Requirements: Non-Functional (Usability)_
