# Tasks Document: Area Management (地域指定機能)

## Phase 1: データ基盤

- [x] 1.1 Area テーブル拡張マイグレーション作成
  - File: db/migrate/xxxx_expand_areas.rb
  - user_id, prefecture, city, address, latitude, longitude, boundary_geojson, description カラム追加
  - Purpose: エリアモデルの地域情報・地図データ保存基盤
  - _Leverage: 既存の areas テーブル構造_
  - _Requirements: REQ-1, REQ-2_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in database migrations | Task: Create migration to expand areas table with user_id (foreign key), prefecture, city, address, latitude (decimal 10,7), longitude (decimal 10,7), boundary_geojson (text), description (text) columns. Add index on user_id and foreign key constraint | Restrictions: Do not modify existing columns (name, position), ensure proper data types for coordinates, keep boundary_geojson as text (not json) for SQLite compatibility | Success: Migration runs without errors, all columns added with correct types, indexes and foreign keys created | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.2 Spot テーブル作成マイグレーション
  - File: db/migrate/xxxx_create_spots.rb
  - contest_id, name, category, address, latitude, longitude, description, position カラム
  - Purpose: コンテストごとの撮影スポット管理テーブル
  - _Leverage: evaluation_criteria テーブル構造（contest_id + position パターン）_
  - _Requirements: REQ-4_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in database design | Task: Create spots table with contest_id (references, not null), name (string 100, not null), category (integer, default 0), address (string 200), latitude/longitude (decimal 10,7), description (text), position (integer, default 0). Add indexes on [contest_id, position] and unique index on [contest_id, name] | Restrictions: Follow existing table patterns like evaluation_criteria, use integer for category enum, foreign key to contests required | Success: Migration creates table with all columns and indexes, foreign key constraint works | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.3 Contest テーブルにエリア関連カラム追加
  - File: db/migrate/xxxx_add_area_to_contests.rb
  - area_id, require_spot カラム追加
  - Purpose: コンテストとエリアの紐付け、スポット必須設定
  - _Leverage: 既存の contests テーブル_
  - _Requirements: REQ-6_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create migration to add area_id (references, optional) and require_spot (boolean, default false) to contests table | Restrictions: area_id must be nullable (contests can exist without area), add foreign key to areas | Success: Migration runs successfully, existing contests unaffected | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.4 Entry テーブルにスポット・位置情報カラム追加
  - File: db/migrate/xxxx_add_location_to_entries.rb
  - spot_id, latitude, longitude, location_source カラム追加
  - Purpose: 投稿の撮影スポット・位置情報保存
  - _Leverage: 既存の entries テーブル（area_id 既存）_
  - _Requirements: REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create migration to add spot_id (references, optional), latitude/longitude (decimal 10,7), location_source (integer, default 0) to entries table | Restrictions: spot_id must be nullable, add foreign key to spots, location_source is enum for manual/exif/gps | Success: Migration runs successfully, existing entries unaffected | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.5 Area モデル拡張
  - File: app/models/area.rb
  - user 関連、新カラムのバリデーション、ヘルパーメソッド追加
  - Purpose: エリアモデルの機能拡張
  - _Leverage: 既存の Area モデル、Contest モデルパターン_
  - _Requirements: REQ-1, REQ-2, REQ-3_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer specializing in ActiveRecord models | Task: Extend Area model with belongs_to :user, has_many :contests. Add validations for name (presence, uniqueness scoped to user_id), prefecture/city/address lengths. Add methods: full_address, has_boundary?, boundary_polygon (parse GeoJSON), center_coordinates, owned_by?(user). Add scope :for_user | Restrictions: Keep existing associations (has_many :entries), follow existing model patterns in codebase | Success: Model validates correctly, all methods work, tests pass | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.6 Spot モデル作成
  - File: app/models/spot.rb
  - アソシエーション、バリデーション、enum、ヘルパーメソッド
  - Purpose: スポットモデルの実装
  - _Leverage: EvaluationCriterion モデルパターン_
  - _Requirements: REQ-4, REQ-5_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create Spot model with belongs_to :contest, has_many :entries (dependent: :nullify). Add enum category (restaurant:0, retail:1, service:2, landmark:3, public_facility:4, park:5, temple_shrine:6, other:99). Add validations for name (presence, uniqueness scoped to contest_id, max 100), position. Add methods: coordinates, category_name (Japanese). Add scope :ordered, callback :set_position | Restrictions: Follow EvaluationCriterion patterns, use dependent: :nullify for entries | Success: Model works correctly, enum functions, all validations pass | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.7 Contest/Entry モデル関連追加
  - File: app/models/contest.rb, app/models/entry.rb
  - area/spot アソシエーション追加、Entry に location_source enum 追加
  - Purpose: 既存モデルへの関連追加
  - _Leverage: 既存の Contest, Entry モデル_
  - _Requirements: REQ-6, REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add to Contest: belongs_to :area (optional: true), has_many :spots (dependent: :destroy). Add to Entry: belongs_to :spot (optional: true), enum location_source (manual:0, exif:1, gps:2, prefix: :location). Add validation to Entry: spot must belong to same contest if present | Restrictions: Do not modify existing associations/validations, area_id/spot_id are optional | Success: Associations work correctly, validations pass, no regressions | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.8 Factory 定義追加
  - File: spec/factories/areas.rb, spec/factories/spots.rb
  - テスト用ファクトリ定義
  - Purpose: テストデータ生成
  - _Leverage: 既存の factories パターン_
  - _Requirements: All_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Developer | Task: Update areas factory with user association and new attributes (prefecture, city, address, latitude, longitude). Create spots factory with contest association, name sequence, category. Add traits for :with_boundary (area), :with_coordinates (spot) | Restrictions: Follow existing factory patterns, use realistic Japanese data for addresses | Success: Factories create valid records, traits work correctly | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 1.9 モデルテスト作成
  - File: spec/models/area_spec.rb, spec/models/spot_spec.rb
  - バリデーション、アソシエーション、メソッドのテスト
  - Purpose: モデル層の品質保証
  - _Leverage: 既存のモデルスペックパターン_
  - _Requirements: REQ-1 through REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Developer | Task: Write comprehensive specs for Area (validations, associations, full_address, has_boundary?, boundary_polygon, center_coordinates, owned_by?) and Spot (validations, associations, enum, coordinates, category_name, scopes). Test edge cases like invalid GeoJSON, missing coordinates | Restrictions: Follow existing spec patterns, use factories, test both positive and negative cases | Success: All specs pass, good coverage of model functionality | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

## Phase 2: エリア管理

- [x] 2.1 Leaflet セットアップ
  - File: config/importmap.rb, app/javascript/controllers/index.js
  - Leaflet ライブラリの importmap 設定
  - Purpose: 地図ライブラリの導入
  - _Leverage: 既存の importmap 設定_
  - _Requirements: REQ-2, REQ-8_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Frontend Developer | Task: Add Leaflet to importmap.rb (pin leaflet from CDN), add Leaflet CSS to application layout. Create app/assets/stylesheets/leaflet_custom.css for map container styles | Restrictions: Use CDN for Leaflet (unpkg or cdnjs), ensure CSS is loaded before JS, set map container height explicitly | Success: Leaflet loads without errors, map can be initialized | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.2 基本地図 Stimulus コントローラー作成
  - File: app/javascript/controllers/map_controller.js
  - Leaflet 地図の初期化、マーカー/ポリゴン表示
  - Purpose: 地図表示の基本機能
  - _Leverage: 既存の Stimulus コントローラーパターン_
  - _Requirements: REQ-2, REQ-8_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Frontend Developer specializing in Stimulus and Leaflet | Task: Create map_controller.js with connect() to initialize Leaflet map with OpenStreetMap tiles. Add targets: container. Add values: latitude, longitude, zoom, boundaryGeojson, markers (JSON). Implement methods: initMap(), setCenter(), addMarker(), addPolygon(), fitBounds(). Handle missing coordinates gracefully | Restrictions: Use OpenStreetMap tiles only, follow Stimulus conventions, support both single marker and boundary display | Success: Map displays correctly, markers and polygons render, responsive to window resize | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.3 エリア管理ルート追加
  - File: config/routes.rb
  - organizers/areas リソースルート追加
  - Purpose: エリア CRUD のルーティング
  - _Leverage: 既存の organizers 名前空間ルート_
  - _Requirements: REQ-1, REQ-3_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add resources :areas to organizers namespace with all standard actions (index, show, new, create, edit, update, destroy) | Restrictions: Place within existing namespace :organizers block, follow existing route patterns | Success: All area routes generated correctly, rails routes shows expected paths | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.4 Organizers::AreasController 作成
  - File: app/controllers/organizers/areas_controller.rb
  - CRUD アクション実装
  - Purpose: エリア管理の Controller 層
  - _Leverage: Organizers::ContestsController パターン_
  - _Requirements: REQ-1, REQ-2, REQ-3_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create AreasController inheriting from Organizers::BaseController. Implement index (current_user's areas), show, new, create, edit, update, destroy. Add before_action :set_area for member actions, authorize_area! for ownership check. Handle destroy with contests check. Use strong params for all area attributes | Restrictions: Only allow access to user's own areas, follow existing controller patterns, return proper flash messages in Japanese | Success: All CRUD operations work, authorization enforced, proper redirects and flash messages | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.5 エリア一覧ビュー作成
  - File: app/views/organizers/areas/index.html.erb
  - エリア一覧表示（カード形式）
  - Purpose: エリア管理の入り口画面
  - _Leverage: organizers/contests/index.html.erb スタイル_
  - _Requirements: REQ-3_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create areas index view with page header (title, new area button), area cards showing name, full_address, contest count. Add empty state when no areas. Style with Tailwind following existing patterns | Restrictions: Follow existing view patterns from contests/index, use Japanese text, include proper link paths | Success: View displays correctly, responsive design, empty state shows | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.6 エリア詳細ビュー作成
  - File: app/views/organizers/areas/show.html.erb
  - エリア詳細と地図プレビュー
  - Purpose: エリア情報の確認画面
  - _Leverage: organizers/contests/show.html.erb スタイル_
  - _Requirements: REQ-3, REQ-8_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create areas show view with header (back link, title, edit/delete buttons), area details (name, full_address, description), map preview using map_controller. Show boundary if present, otherwise show marker at center. List associated contests | Restrictions: Follow existing show view patterns, handle missing coordinates gracefully, use data attributes for Stimulus | Success: View displays area details and map correctly, actions work | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.7 エリアフォームパーシャル作成
  - File: app/views/organizers/areas/_form.html.erb
  - エリア作成・編集フォーム（地図付き）
  - Purpose: エリア入力 UI
  - _Leverage: organizers/evaluation_criteria/_form.html.erb スタイル_
  - _Requirements: REQ-1, REQ-2_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create areas form partial with fields for name, prefecture (select), city, address, description. Include map div for coordinate selection. Add hidden fields for latitude, longitude, boundary_geojson. Integrate with map_controller for click-to-set-coordinates | Restrictions: Follow existing form patterns, use form_with, include error display, prefecture should be select with 47 prefectures | Success: Form submits correctly, map interaction works, validation errors display | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.8 エリア new/edit ビュー作成
  - File: app/views/organizers/areas/new.html.erb, app/views/organizers/areas/edit.html.erb
  - 新規作成・編集ページ
  - Purpose: フォームのラッパービュー
  - _Leverage: 既存の new/edit ビューパターン_
  - _Requirements: REQ-1, REQ-2_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create new.html.erb and edit.html.erb views with page headers and form partial render. Include back link to areas index | Restrictions: Follow existing patterns from evaluation_criteria views, use Japanese headings | Success: Both views render correctly with form | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.9 座標選択 Stimulus コントローラー作成
  - File: app/javascript/controllers/coordinate_picker_controller.js
  - 地図クリックで座標を hidden field に設定
  - Purpose: フォームでの座標入力支援
  - _Leverage: map_controller.js_
  - _Requirements: REQ-2_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Frontend Developer | Task: Create coordinate_picker_controller.js that extends/uses map_controller. Add targets: latitudeInput, longitudeInput, coordinateDisplay. On map click, update hidden inputs and show selected coordinates. Add method to clear selection. Show marker at selected position | Restrictions: Work with existing form structure, update hidden fields on click, provide visual feedback | Success: Clicking map sets coordinates in form fields, marker shows selection | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 2.10 エリア管理リクエストスペック作成
  - File: spec/requests/organizers/areas_spec.rb
  - CRUD 操作、認可のテスト
  - Purpose: Controller 層の品質保証
  - _Leverage: spec/requests/organizers/contests_spec.rb パターン_
  - _Requirements: REQ-1, REQ-2, REQ-3_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Developer | Task: Write request specs for AreasController covering: index (lists user's areas), show, new, create (valid/invalid params), edit, update, destroy (with/without contests). Test authorization (other user's areas rejected). Follow existing patterns | Restrictions: Use factories, test both success and failure scenarios, verify flash messages | Success: All specs pass, good coverage of controller actions and authorization | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

## Phase 3: スポット管理

- [x] 3.1 スポット管理ルート追加
  - File: config/routes.rb
  - contests/:contest_id/spots ネストリソース追加
  - Purpose: スポット CRUD のルーティング
  - _Leverage: contests/:contest_id/evaluation_criteria ルートパターン_
  - _Requirements: REQ-4, REQ-5_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add resources :spots (except: [:show]) nested under contests in organizers namespace. Add member route for update_positions (patch) | Restrictions: Follow existing nested resource patterns like evaluation_criteria, no show action needed | Success: All spot routes generated correctly | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 3.2 Organizers::SpotsController 作成
  - File: app/controllers/organizers/spots_controller.rb
  - CRUD アクション実装
  - Purpose: スポット管理の Controller 層
  - _Leverage: Organizers::EvaluationCriteriaController パターン_
  - _Requirements: REQ-4, REQ-5_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create SpotsController inheriting from Organizers::BaseController. Implement index, new, create, edit, update, destroy, update_positions. Set @contest via before_action, authorize contest ownership. Handle destroy with entries check (confirm or nullify). Add strong params for spot attributes | Restrictions: Only contest owner can manage spots, follow EvaluationCriteriaController patterns, handle entries association on destroy | Success: All CRUD operations work, authorization enforced, position update works | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 3.3 スポット一覧ビュー作成
  - File: app/views/organizers/spots/index.html.erb
  - スポット一覧と地図表示
  - Purpose: スポット管理の入り口画面
  - _Leverage: organizers/evaluation_criteria/index.html.erb スタイル_
  - _Requirements: REQ-4, REQ-5_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create spots index view with header (back to contest, title, add button), spots list (name, category badge, entry count, edit/delete links), map showing all spots as markers. Add empty state. Support drag-and-drop reordering | Restrictions: Follow existing patterns, show category in Japanese, use map_controller for map display | Success: View displays correctly, map shows all spots, actions work | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 3.4 スポットフォームパーシャル作成
  - File: app/views/organizers/spots/_form.html.erb
  - スポット作成・編集フォーム
  - Purpose: スポット入力 UI
  - _Leverage: organizers/evaluation_criteria/_form.html.erb_
  - _Requirements: REQ-4_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create spots form partial with fields for name, category (select with Japanese labels), address, description. Include map for coordinate selection with coordinate_picker_controller. Hidden fields for latitude, longitude | Restrictions: Follow existing form patterns, category select should show Japanese names | Success: Form submits correctly, map coordinate selection works | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 3.5 スポット new/edit ビュー作成
  - File: app/views/organizers/spots/new.html.erb, app/views/organizers/spots/edit.html.erb
  - 新規作成・編集ページ
  - Purpose: フォームのラッパービュー
  - _Leverage: 既存の new/edit ビューパターン_
  - _Requirements: REQ-4, REQ-5_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Create new.html.erb and edit.html.erb views with page headers and form partial render. Include back link to spots index | Restrictions: Follow existing patterns, use Japanese headings | Success: Both views render correctly with form | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 3.6 MapHelper 作成
  - File: app/helpers/map_helper.rb
  - 地図関連のヘルパーメソッド
  - Purpose: ビューでの地図データ生成支援
  - _Leverage: 既存のヘルパーパターン_
  - _Requirements: REQ-8, REQ-9_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Create MapHelper with methods: spots_to_markers_json(spots), area_map_data(area), default_map_center (Tokyo), prefecture_coordinates_for(prefecture). Return JSON-safe hashes for Stimulus data values | Restrictions: Handle nil coordinates gracefully, return valid JSON structures | Success: Helper methods generate correct data for map display | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 3.7 スポット管理リクエストスペック作成
  - File: spec/requests/organizers/spots_spec.rb
  - CRUD 操作、認可のテスト
  - Purpose: Controller 層の品質保証
  - _Leverage: spec/requests/organizers/evaluation_criteria_spec.rb パターン_
  - _Requirements: REQ-4, REQ-5_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Developer | Task: Write request specs for SpotsController covering all actions, authorization (non-owner rejected), destroy with entries handling, update_positions. Follow existing patterns | Restrictions: Use factories, test authorization thoroughly | Success: All specs pass, good coverage | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

## Phase 4: コンテスト連携

- [x] 4.1 コンテストフォームにエリア選択追加
  - File: app/views/organizers/contests/_form.html.erb
  - エリア選択ドロップダウンと地図プレビュー
  - Purpose: コンテスト作成時のエリア設定
  - _Leverage: 既存のコンテストフォーム_
  - _Requirements: REQ-6_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Add area selection section to contests form with select field (user's areas), require_spot checkbox. Add map preview div that updates when area selected. Use Stimulus to show area boundary/marker on selection | Restrictions: Keep existing form structure intact, area is optional, add as new section | Success: Area selection works, map preview updates on change | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 4.2 ContestsController にエリアパラメータ追加
  - File: app/controllers/organizers/contests_controller.rb
  - area_id, require_spot を strong params に追加
  - Purpose: エリア設定の保存
  - _Leverage: 既存の contests_controller_
  - _Requirements: REQ-6_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add :area_id and :require_spot to contest_params. Add @areas = current_user.areas.ordered to new/edit actions for form select | Restrictions: Minimal changes to existing controller, area_id must be validated to belong to current_user | Success: Contest can be created/updated with area, validation works | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 4.3 コンテスト詳細にエリア・スポット管理リンク追加
  - File: app/views/organizers/contests/show.html.erb
  - エリア情報表示とスポット管理へのリンク
  - Purpose: エリア・スポット管理への導線
  - _Leverage: 既存のコンテスト詳細ビュー_
  - _Requirements: REQ-6, REQ-4_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Add area section to contest show view: display area name with link to area show, show map preview if area has coordinates. Add "スポット管理" action card linking to spots index with spot count badge | Restrictions: Only show area section if area is set, maintain existing layout structure | Success: Area info displays correctly, links work, map shows if coordinates exist | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 4.4 コンテスト連携テスト追加
  - File: spec/requests/organizers/contests_spec.rb
  - エリア選択関連のテスト追加
  - Purpose: コンテスト-エリア連携の品質保証
  - _Leverage: 既存の contests_spec.rb_
  - _Requirements: REQ-6_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Developer | Task: Add specs for contest creation/update with area_id, verify area must belong to current_user, test require_spot setting. Add to existing contests_spec.rb | Restrictions: Add to existing spec file, don't duplicate existing tests | Success: New specs pass, area integration tested | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

## Phase 5: 投稿連携

- [x] 5.1 投稿フォームにスポット選択追加
  - File: app/views/entries/_form.html.erb (または該当ファイル)
  - スポット選択ドロップダウンと地図
  - Purpose: 投稿時のスポット設定
  - _Leverage: 既存の投稿フォーム_
  - _Requirements: REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Add spot selection section to entry form (only if contest has spots). Include select field with contest's spots, map showing spots as markers. Implement spot_picker_controller to select from map. Respect require_spot setting for validation message | Restrictions: Only show if contest.spots.any?, handle require_spot validation client-side hint | Success: Spot selection works, map click selects spot, required validation shows | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 5.2 スポット選択 Stimulus コントローラー作成
  - File: app/javascript/controllers/spot_picker_controller.js
  - 地図上のスポット選択機能
  - Purpose: 投稿時のスポット選択 UI
  - _Leverage: map_controller.js_
  - _Requirements: REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Frontend Developer | Task: Create spot_picker_controller.js with targets: selectInput, mapContainer. Add values: spots (JSON array). Display spots as markers, on marker click select spot and update select input. Highlight selected marker. Sync select dropdown with map selection | Restrictions: Two-way binding between select and map, visual feedback for selection | Success: Spot can be selected from map or dropdown, both stay in sync | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 5.3 EntriesController にスポットパラメータ追加
  - File: app/controllers/entries_controller.rb
  - spot_id を strong params に追加、バリデーション
  - Purpose: スポット設定の保存
  - _Leverage: 既存の entries_controller_
  - _Requirements: REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Developer | Task: Add :spot_id to entry_params. Add @spots = @contest.spots.ordered to new/create actions. Validate spot belongs to contest in model | Restrictions: Minimal changes, spot_id is optional unless contest.require_spot | Success: Entry can be created with spot, validation works | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 5.4 投稿詳細にスポット情報表示
  - File: app/views/entries/show.html.erb
  - スポット名と地図上の位置表示
  - Purpose: 投稿のスポット情報表示
  - _Leverage: 既存の投稿詳細ビュー_
  - _Requirements: REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Add spot info section to entry show: display spot name with category badge if spot is set. Show mini map with spot marker if coordinates exist | Restrictions: Only show if entry.spot present, keep existing layout | Success: Spot info displays correctly with map | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 5.5 投稿連携テスト追加
  - File: spec/requests/entries_spec.rb
  - スポット選択関連のテスト追加
  - Purpose: 投稿-スポット連携の品質保証
  - _Leverage: 既存の entries_spec.rb_
  - _Requirements: REQ-7_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Developer | Task: Add specs for entry creation with spot_id, verify spot must belong to contest, test require_spot validation. Add to existing entries spec | Restrictions: Add to existing spec file | Success: New specs pass, spot integration tested | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

## Phase 6: 地図表示（参加者向け）

- [x] 6.1 コンテスト詳細（参加者向け）に地図追加
  - File: app/views/contests/show.html.erb
  - エリア境界とスポットマーカー表示
  - Purpose: 参加者向けエリア・スポット情報
  - _Leverage: 主催者向け地図表示_
  - _Requirements: REQ-8_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Add map section to public contest show view (only if area or spots exist). Show area boundary polygon if present, spots as clickable markers with popup (name, category). Style map container appropriately | Restrictions: Read-only map, no editing features, graceful handling if no location data | Success: Map displays correctly with area and spots | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 6.2 投稿一覧マップモード追加
  - File: app/views/organizers/entries/index.html.erb (または contests/entries)
  - 投稿を地図上にマーカー表示
  - Purpose: 投稿の地理的分布確認
  - _Leverage: map_controller.js_
  - _Requirements: REQ-9_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Frontend Developer | Task: Add map/list toggle to entries index. In map mode, show entries with spots as markers (use spot coordinates). Cluster markers if multiple at same spot. Marker popup shows entry thumbnail and title, links to entry show | Restrictions: Only entries with spot coordinates shown on map, provide fallback list view | Success: Map mode shows entries, clicking opens popup, toggle works | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 6.3 マーカークラスタリング実装
  - File: app/javascript/controllers/map_controller.js
  - 同一位置のマーカーをクラスタリング
  - Purpose: 多数マーカーの見やすい表示
  - _Leverage: Leaflet.markercluster プラグイン_
  - _Requirements: REQ-9_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Frontend Developer | Task: Add marker clustering to map_controller using Leaflet.markercluster plugin. Add to importmap. Enable clustering when markers value contains multiple items. Style clusters appropriately | Restrictions: Only cluster when needed (>5 markers), maintain individual marker click functionality | Success: Multiple markers at same location cluster, cluster shows count | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_

- [x] 6.4 システムテスト作成
  - File: spec/system/organizers/area_management_spec.rb, spec/system/organizers/spot_management_spec.rb
  - E2E テスト
  - Purpose: 全体フローの品質保証
  - _Leverage: 既存のシステムテストパターン_
  - _Requirements: All_
  - _Prompt: Implement the task for spec area-management, first run spec-workflow-guide to get the workflow guide then implement the task: Role: Rails Test Developer | Task: Create system specs for: area creation flow (form, map interaction), spot management flow, contest with area selection, entry with spot selection. Use Capybara with headless Chrome | Restrictions: Test user journeys not implementation details, handle async map loading | Success: System tests pass, cover main user flows | Instructions: Mark task as in-progress in tasks.md before starting, use log-implementation tool after completion, then mark as complete_
