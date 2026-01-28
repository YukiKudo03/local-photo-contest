# Tasks Document: Contest Templates

- [x] 1. ContestTemplate マイグレーション作成
  - File: db/migrate/YYYYMMDDHHMMSS_create_contest_templates.rb
  - contest_templates テーブルを作成
  - user_id, source_contest_id, name, theme, description, judging_method, judge_weight, prize_count, moderation_enabled, moderation_threshold, require_spot, area_id, category_id カラム
  - user_id + name のユニークインデックス
  - Purpose: テンプレートデータを永続化するテーブルを作成
  - _Leverage: db/schema.rb の既存パターン_
  - _Requirements: 4（保存される設定項目）_
  - _Prompt: Role: Rails Developer | Task: ContestTemplate モデル用のマイグレーションを作成。user_id（必須）、source_contest_id（オプショナル）、name（必須、100文字）、theme、description、judging_method、judge_weight、prize_count、moderation_enabled、moderation_threshold、require_spot、area_id、category_id カラムを含む。user_id + name にユニークインデックス | Restrictions: 既存スキーマを壊さない | Success: rails db:migrate が成功、テーブルが作成される_

- [x] 2. ContestTemplate モデル作成
  - File: app/models/contest_template.rb
  - belongs_to :user, :source_contest, :category, :area 関連
  - name のバリデーション（presence, length）
  - owned_by? メソッド
  - スコープ: owned_by, recent
  - Purpose: テンプレートデータのモデル層を実装
  - _Leverage: app/models/contest.rb のパターン_
  - _Requirements: 5（アクセス制御）_
  - _Prompt: Role: Rails Model Developer | Task: ContestTemplate モデルを作成。belongs_to :user（必須）、belongs_to :source_contest（class_name: "Contest", optional: true）、belongs_to :category/area（optional）。name のバリデーション（presence, maximum: 100）。owned_by?(user) メソッド、owned_by/recent スコープ | Restrictions: Contest モデルとの疎結合維持 | Success: バリデーションが動作、関連が正しく設定される_

- [x] 3. TemplateService 作成
  - File: app/services/template_service.rb
  - TEMPLATE_FIELDS 定数でコピー対象フィールドを定義
  - create_from_contest(contest, name:, user:) メソッド
  - apply_to_contest(template, contest) メソッド
  - template_attributes(contest) メソッド
  - Purpose: テンプレート操作のビジネスロジックをカプセル化
  - _Leverage: app/services/ranking_calculator.rb のパターン_
  - _Requirements: 1, 2（テンプレート保存、テンプレートから作成）_
  - _Prompt: Role: Rails Service Developer | Task: TemplateService を作成。TEMPLATE_FIELDS = [:theme, :description, :judging_method, :judge_weight, :prize_count, :moderation_enabled, :moderation_threshold, :require_spot, :area_id, :category_id]。create_from_contest でコンテストからテンプレート作成、apply_to_contest でテンプレートをコンテストに適用（save しない）、template_attributes で属性抽出 | Restrictions: title, entry_start_at, entry_end_at, status は除外 | Success: テンプレート作成・適用が正しく動作_

- [x] 4. Organizers::ContestTemplatesController 作成
  - File: app/controllers/organizers/contest_templates_controller.rb
  - BaseController を継承
  - index, new, create, destroy アクション
  - before_action で set_template, authorize_template!
  - Purpose: テンプレートのCRUD操作を処理
  - _Leverage: app/controllers/organizers/contests_controller.rb のパターン_
  - _Requirements: 1, 3, 5（テンプレート保存、一覧管理、アクセス制御）_
  - _Prompt: Role: Rails Controller Developer | Task: Organizers::ContestTemplatesController を作成。BaseController を継承。index（一覧）、new（contest_id パラメータからフォーム表示）、create（TemplateService 使用）、destroy（削除）アクション。set_template、authorize_template! で認可 | Restrictions: 他主催者のテンプレートはアクセス拒否 | Success: CRUD 操作が正しく動作_

- [x] 5. ルーティング設定
  - File: config/routes.rb
  - organizers 名前空間に contest_templates リソースを追加
  - only: [:index, :new, :create, :destroy]
  - Purpose: テンプレート機能へのルートを定義
  - _Leverage: 既存の organizers namespace ルーティング_
  - _Requirements: All_
  - _Prompt: Role: Rails Developer | Task: config/routes.rb の organizers namespace 内に resources :contest_templates, only: [:index, :new, :create, :destroy] を追加 | Restrictions: 既存ルートを壊さない | Success: organizers_contest_templates_path 等のヘルパーが利用可能_

- [x] 6. テンプレート一覧ビュー作成
  - File: app/views/organizers/contest_templates/index.html.erb
  - テンプレート一覧をカード形式で表示
  - 各テンプレートに名前、作成日、元コンテスト名を表示
  - 「このテンプレートから作成」「削除」ボタン
  - テンプレートがない場合の空状態メッセージ
  - Purpose: テンプレート一覧の表示
  - _Leverage: app/views/organizers/contests/index.html.erb のレイアウト_
  - _Requirements: 3（テンプレート一覧管理）_
  - _Prompt: Role: Rails View Developer | Task: テンプレート一覧ビューを作成。カード形式で各テンプレートを表示（名前、作成日、元コンテスト名）。「このテンプレートから作成」リンク（new_organizers_contest_path(template_id: template.id)）、削除ボタン（確認ダイアログ付き）。空の場合は「テンプレートがありません」メッセージ | Restrictions: Tailwind CSS、既存レイアウトとの整合性 | Success: 一覧が正しく表示、削除確認が動作_

- [x] 7. テンプレート作成フォームビュー作成
  - File: app/views/organizers/contest_templates/new.html.erb
  - テンプレート名入力フォーム
  - 元コンテスト情報の表示
  - 保存されるフィールドのプレビュー表示
  - Purpose: テンプレート保存フォームの表示
  - _Leverage: 既存フォームパターン_
  - _Requirements: 1（テンプレート保存）_
  - _Prompt: Role: Rails View Developer | Task: テンプレート作成フォームを作成。テンプレート名入力フィールド、元コンテスト情報（タイトル）表示、保存される設定項目のプレビュー（theme、description、judging_method 等）。form_with model: [@contest_template] | Restrictions: Tailwind CSS、シンプルなフォーム | Success: フォームが正しく表示、送信が動作_

- [x] 8. コンテスト詳細ページに「テンプレートとして保存」ボタン追加
  - File: app/views/organizers/contests/show.html.erb
  - 「テンプレートとして保存」リンクを追加
  - new_organizers_contest_template_path(contest_id: @contest.id) へリンク
  - Purpose: テンプレート保存への導線を確保
  - _Leverage: 既存のボタンレイアウト_
  - _Requirements: 1（テンプレート保存）_
  - _Prompt: Role: Rails View Developer | Task: コンテスト詳細ページに「テンプレートとして保存」リンクを追加。new_organizers_contest_template_path(contest_id: @contest.id) へ遷移 | Restrictions: 既存ボタン群との整合性 | Success: リンクが表示、正しく遷移_

- [x] 9. コンテスト新規作成でテンプレート選択機能
  - File: app/controllers/organizers/contests_controller.rb, app/views/organizers/contests/new.html.erb
  - new アクションで template_id パラメータを受け取る
  - テンプレートがある場合は TemplateService.apply_to_contest でプリセット
  - ビューにテンプレート選択ドロップダウンを追加
  - Purpose: テンプレートからのコンテスト作成を実現
  - _Leverage: 既存の new/create フロー_
  - _Requirements: 2（テンプレートから新規コンテスト作成）_
  - _Prompt: Role: Rails Full-stack Developer | Task: ContestsController#new で template_id パラメータを受け取り、存在すればテンプレートから設定をプリセット。ビューにテンプレート選択ドロップダウン追加（テンプレートがある場合のみ表示）。選択時に Stimulus で画面遷移またはフォーム更新 | Restrictions: 日付フィールドは空のまま、既存フォームの動作を壊さない | Success: テンプレート選択でフォームがプリセットされる_

- [x] 10. テンプレート選択用 Stimulus コントローラー
  - File: app/javascript/controllers/template_selector_controller.js
  - テンプレート選択時にページ遷移（template_id パラメータ付き）
  - または Turbo Frame でフォーム更新
  - Purpose: テンプレート選択のインタラクティブな動作を実現
  - _Leverage: 既存の Stimulus コントローラーパターン_
  - _Requirements: 2（テンプレートから作成）_
  - _Prompt: Role: Stimulus Developer | Task: template_selector_controller.js を作成。select 要素の変更時に、選択されたテンプレートIDで new_organizers_contest_path にリダイレクト | Restrictions: シンプルな実装、Turbo と連携 | Success: テンプレート選択でページ遷移、フォームがプリセットされる_

- [x] 11. サイドメニューにテンプレートリンク追加
  - File: app/views/layouts/organizers.html.erb または該当するナビゲーションパーシャル
  - 「テンプレート」リンクを追加
  - organizers_contest_templates_path へリンク
  - Purpose: テンプレート一覧への導線を確保
  - _Leverage: 既存ナビゲーション構造_
  - _Requirements: 3（テンプレート一覧管理）_
  - _Prompt: Role: Rails View Developer | Task: 主催者向けサイドメニューに「テンプレート」リンクを追加 | Restrictions: 既存ナビゲーションとの整合性 | Success: リンクが表示、正しく遷移_

- [x] 12. ContestTemplate モデルユニットテスト
  - File: spec/models/contest_template_spec.rb
  - バリデーションテスト（name 必須、長さ、ユニーク制約）
  - 関連テスト（belongs_to user, source_contest, category, area）
  - owned_by? メソッドテスト
  - スコープテスト
  - Purpose: モデルの信頼性を確保
  - _Leverage: spec/models/ の既存テストパターン_
  - _Requirements: All_
  - _Prompt: Role: Rails Test Engineer | Task: ContestTemplate モデルのユニットテストを作成。name のバリデーション、ユニーク制約（user_id + name）、関連、owned_by? メソッド、スコープをテスト | Restrictions: FactoryBot 使用 | Success: 全テスト通過_

- [x] 13. TemplateService ユニットテスト
  - File: spec/services/template_service_spec.rb
  - create_from_contest テスト（正常系、バリデーションエラー）
  - apply_to_contest テスト（フィールドが正しくコピーされる）
  - template_attributes テスト（必要なフィールドのみ抽出）
  - Purpose: サービスクラスの信頼性を確保
  - _Leverage: spec/services/ の既存テストパターン_
  - _Requirements: 1, 2, 4_
  - _Prompt: Role: Rails Test Engineer | Task: TemplateService のユニットテストを作成。create_from_contest（正常、エラー）、apply_to_contest（全フィールドコピー、日付は除外）、template_attributes をテスト | Restrictions: FactoryBot 使用 | Success: 全テスト通過_

- [x] 14. ContestTemplate ファクトリー作成
  - File: spec/factories/contest_templates.rb
  - 基本ファクトリーと trait を定義
  - Purpose: テストデータ生成を容易にする
  - _Leverage: spec/factories/ の既存パターン_
  - _Requirements: All_
  - _Prompt: Role: Rails Test Engineer | Task: ContestTemplate 用の FactoryBot ファクトリーを作成。user 関連、基本属性を設定 | Restrictions: 既存ファクトリーとの整合性 | Success: ファクトリーが正しく動作_

- [x] 15. ContestTemplatesController Request Spec
  - File: spec/requests/organizers/contest_templates_spec.rb
  - 認証なしアクセス → リダイレクト
  - 他主催者のテンプレートアクセス → アクセス拒否
  - index, new, create, destroy の正常系テスト
  - バリデーションエラー時の動作テスト
  - Purpose: コントローラーの動作を検証
  - _Leverage: spec/requests/organizers/ の既存パターン_
  - _Requirements: 1, 3, 5_
  - _Prompt: Role: Rails Test Engineer | Task: Organizers::ContestTemplatesController の Request Spec を作成。認証、認可、CRUD 操作をテスト | Restrictions: sign_in ヘルパー使用、FactoryBot | Success: 全アクセス制御パターンのテスト通過_

- [x] 16. System Spec 作成
  - File: spec/system/organizers/contest_templates_spec.rb
  - 主催者がテンプレートを保存
  - 主催者がテンプレート一覧を表示
  - 主催者がテンプレートから新規コンテストを作成
  - 主催者がテンプレートを削除
  - Purpose: E2E でのユーザー体験を検証
  - _Leverage: spec/system/ の既存テストパターン_
  - _Requirements: All_
  - _Prompt: Role: Rails E2E Test Engineer | Task: コンテストテンプレートの System Spec を作成。テンプレート保存、一覧表示、テンプレートから作成、削除のフローをテスト | Restrictions: Capybara 使用、JavaScript 有効化 | Success: E2E テスト通過_
