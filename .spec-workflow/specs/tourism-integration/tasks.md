# Tasks Document: Tourism Integration

- [x] 1. Spot モデル拡張マイグレーション作成
  - File: db/migrate/YYYYMMDDHHMMSS_add_discovery_fields_to_spots.rb
  - discovery_status, discovered_by_id, discovered_at, discovery_comment, certified_by_id, certified_at, rejection_reason, votes_count カラム追加
  - インデックス追加（discovery_status, discovered_by_id）
  - Purpose: スポットに発掘機能のフィールドを追加
  - _Leverage: db/schema.rb の既存パターン_
  - _Requirements: 1, 2（発掘スポット投稿、認定）_
  - _Prompt: Role: Rails Developer | Task: Spot モデルに発掘機能用のカラムを追加するマイグレーションを作成。discovery_status（integer, default: 0）、discovered_by_id（references users）、discovered_at（datetime）、discovery_comment（text）、certified_by_id（references users）、certified_at（datetime）、rejection_reason（text）、votes_count（integer, default: 0）。discovery_status と discovered_by_id にインデックス | Restrictions: 既存スキーマを壊さない、null許容で後方互換性維持 | Success: rails db:migrate が成功_

- [x] 2. DiscoveryChallenge マイグレーション作成
  - File: db/migrate/YYYYMMDDHHMMSS_create_discovery_challenges.rb
  - discovery_challenges テーブルを作成
  - contest_id, name, description, theme, starts_at, ends_at, status カラム
  - Purpose: 発掘チャレンジデータを永続化するテーブルを作成
  - _Leverage: db/schema.rb の既存パターン_
  - _Requirements: 3（発掘チャレンジ）_
  - _Prompt: Role: Rails Developer | Task: DiscoveryChallenge モデル用のマイグレーションを作成。contest_id（null: false）、name（limit: 100, null: false）、description（text）、theme（limit: 100）、starts_at、ends_at、status（integer, default: 0）。contest_id にインデックス | Restrictions: 既存スキーマを壊さない | Success: rails db:migrate が成功_

- [x] 3. SpotVote マイグレーション作成
  - File: db/migrate/YYYYMMDDHHMMSS_create_spot_votes.rb
  - spot_votes テーブルを作成
  - user_id, spot_id カラム、ユニーク制約
  - Purpose: スポット投票データを永続化
  - _Leverage: db/migrate/..._create_votes.rb のパターン_
  - _Requirements: 6（隠れた名所投票）_
  - _Prompt: Role: Rails Developer | Task: SpotVote モデル用のマイグレーションを作成。user_id（null: false）、spot_id（null: false）。user_id + spot_id にユニークインデックス | Restrictions: votes テーブルとの整合性 | Success: rails db:migrate が成功_

- [x] 4. DiscoveryBadge マイグレーション作成
  - File: db/migrate/YYYYMMDDHHMMSS_create_discovery_badges.rb
  - discovery_badges テーブルを作成
  - user_id, contest_id, badge_type, earned_at, metadata カラム
  - Purpose: 発掘バッジデータを永続化
  - _Leverage: db/schema.rb の既存パターン_
  - _Requirements: 5（発掘ランキング）_
  - _Prompt: Role: Rails Developer | Task: DiscoveryBadge モデル用のマイグレーションを作成。user_id（null: false）、contest_id（null: false）、badge_type（integer, null: false）、earned_at（datetime）、metadata（json）。user_id + contest_id + badge_type にユニークインデックス | Restrictions: 既存スキーマを壊さない | Success: rails db:migrate が成功_

- [x] 5. ChallengeEntry マイグレーション作成
  - File: db/migrate/YYYYMMDDHHMMSS_create_challenge_entries.rb
  - challenge_entries テーブルを作成（中間テーブル）
  - discovery_challenge_id, entry_id カラム
  - Purpose: チャレンジとエントリーの多対多関係を実現
  - _Leverage: db/schema.rb の中間テーブルパターン_
  - _Requirements: 3（発掘チャレンジ）_
  - _Prompt: Role: Rails Developer | Task: ChallengeEntry 中間テーブル用のマイグレーションを作成。discovery_challenge_id（null: false）、entry_id（null: false）。両カラムの複合ユニークインデックス | Restrictions: 既存スキーマを壊さない | Success: rails db:migrate が成功_

- [x] 6. Spot モデル拡張
  - File: app/models/spot.rb
  - discovery_status enum 追加（organizer_created, discovered, certified, rejected）
  - discovered_by, certified_by 関連追加
  - has_many :spot_votes, :discovery_badges 追加
  - 発掘関連スコープ追加（discovered, certified, pending_certification）
  - Purpose: Spotモデルに発掘機能を追加
  - _Leverage: app/models/spot.rb 既存パターン_
  - _Requirements: 1, 2（発掘スポット投稿、認定）_
  - _Prompt: Role: Rails Model Developer | Task: Spot モデルを拡張。enum :discovery_status（organizer_created: 0, discovered: 1, certified: 2, rejected: 3）。belongs_to :discovered_by（class_name: "User", optional: true）、belongs_to :certified_by（class_name: "User", optional: true）。has_many :spot_votes。スコープ: discovered, certified, pending_certification（where discovery_status: :discovered） | Restrictions: 既存機能を壊さない | Success: 発掘ステータス管理が正しく動作_

- [x] 7. DiscoveryChallenge モデル作成
  - File: app/models/discovery_challenge.rb
  - belongs_to :contest 関連
  - has_many :challenge_entries, :entries 関連
  - status enum（draft, active, finished）
  - バリデーション（name 必須、期間整合性）
  - スコープ（active, upcoming, past）
  - Purpose: 発掘チャレンジのモデル層を実装
  - _Leverage: app/models/contest.rb のパターン_
  - _Requirements: 3（発掘チャレンジ）_
  - _Prompt: Role: Rails Model Developer | Task: DiscoveryChallenge モデルを作成。belongs_to :contest。has_many :challenge_entries、has_many :entries, through: :challenge_entries。enum :status（draft: 0, active: 1, finished: 2）。validates :name（presence, maximum: 100）。validate :end_date_after_start_date。スコープ: active（status: :active かつ期間内）、upcoming、past | Restrictions: Contest モデルとの疎結合維持 | Success: バリデーション・スコープが正しく動作_

- [x] 8. SpotVote モデル作成
  - File: app/models/spot_vote.rb
  - belongs_to :user, :spot 関連
  - ユニークバリデーション
  - カウンターキャッシュ設定
  - Purpose: スポット投票のモデル層を実装
  - _Leverage: app/models/vote.rb のパターン_
  - _Requirements: 6（隠れた名所投票）_
  - _Prompt: Role: Rails Model Developer | Task: SpotVote モデルを作成。belongs_to :user、belongs_to :spot（counter_cache: :votes_count）。validates :user_id, uniqueness: { scope: :spot_id } | Restrictions: Vote モデルとの整合性 | Success: 投票・重複防止が正しく動作_

- [x] 9. DiscoveryBadge モデル作成
  - File: app/models/discovery_badge.rb
  - belongs_to :user, :contest 関連
  - badge_type enum（pioneer, explorer, curator, master）
  - ユニークバリデーション
  - Purpose: 発掘バッジのモデル層を実装
  - _Leverage: app/models/ の既存パターン_
  - _Requirements: 5（発掘ランキング）_
  - _Prompt: Role: Rails Model Developer | Task: DiscoveryBadge モデルを作成。belongs_to :user、belongs_to :contest。enum :badge_type（pioneer: 0, explorer: 1, curator: 2, master: 3）。validates :badge_type, uniqueness: { scope: [:user_id, :contest_id] } | Restrictions: 重複バッジ防止 | Success: バッジ付与が正しく動作_

- [x] 10. ChallengeEntry モデル作成
  - File: app/models/challenge_entry.rb
  - belongs_to :discovery_challenge, :entry 関連
  - ユニークバリデーション
  - Purpose: チャレンジ参加の中間モデルを実装
  - _Leverage: app/models/ の中間テーブルパターン_
  - _Requirements: 3（発掘チャレンジ）_
  - _Prompt: Role: Rails Model Developer | Task: ChallengeEntry 中間モデルを作成。belongs_to :discovery_challenge、belongs_to :entry。validates :entry_id, uniqueness: { scope: :discovery_challenge_id } | Restrictions: N+1 問題に注意 | Success: チャレンジ参加が正しく動作_

- [x] 11. User モデル関連追加
  - File: app/models/user.rb
  - has_many :discovered_spots, :certified_spots, :spot_votes, :discovery_badges 追加
  - Purpose: Userからの発掘関連へのアクセスを可能にする
  - _Leverage: app/models/user.rb 既存パターン_
  - _Requirements: 5（発掘ランキング）_
  - _Prompt: Role: Rails Model Developer | Task: User モデルに発掘関連の has_many を追加。has_many :discovered_spots（class_name: "Spot", foreign_key: :discovered_by_id）、has_many :certified_spots（class_name: "Spot", foreign_key: :certified_by_id）、has_many :spot_votes, dependent: :destroy、has_many :discovery_badges, dependent: :destroy | Restrictions: 既存関連を壊さない | Success: User から発掘データにアクセス可能_

- [x] 12. Contest モデル関連追加
  - File: app/models/contest.rb
  - has_many :discovery_challenges 追加
  - Purpose: Contestから発掘チャレンジへのアクセスを可能にする
  - _Leverage: app/models/contest.rb 既存パターン_
  - _Requirements: 3（発掘チャレンジ）_
  - _Prompt: Role: Rails Model Developer | Task: Contest モデルに has_many :discovery_challenges, dependent: :destroy を追加 | Restrictions: 既存関連を壊さない | Success: Contest からチャレンジにアクセス可能_

- [x] 13. DiscoverySpotService 作成
  - File: app/services/discovery_spot_service.rb
  - create_discovered_spot, certify_spot, reject_spot, merge_spots メソッド
  - find_nearby_spots（距離計算）メソッド
  - discovery_statistics メソッド
  - Purpose: 発掘スポット操作のビジネスロジックをカプセル化
  - _Leverage: app/services/ranking_calculator.rb, app/services/statistics_service.rb のパターン_
  - _Requirements: 1, 2, 7（発掘、認定、統計）_
  - _Prompt: Role: Rails Service Developer | Task: DiscoverySpotService を作成。create_discovered_spot（entry, name, lat, lng, comment から Spot を作成、discovery_status: :discovered）、certify_spot（spot を :certified に変更、通知送信）、reject_spot（spot を :rejected に変更、理由付き通知）、merge_spots（重複スポットを統合）、find_nearby_spots（Haversine 距離計算で半径内スポット検索）、discovery_statistics（コンテストの発掘統計） | Restrictions: トランザクション管理、通知失敗時もロールバックしない | Success: 全メソッドが正しく動作_

- [x] 14. Organizers::DiscoverySpotsController 作成
  - File: app/controllers/organizers/discovery_spots_controller.rb
  - BaseController を継承
  - index, certify, reject, merge アクション
  - Purpose: 発掘スポットの審査・管理を処理
  - _Leverage: app/controllers/organizers/moderation_controller.rb のパターン_
  - _Requirements: 2（発掘スポット認定）_
  - _Prompt: Role: Rails Controller Developer | Task: Organizers::DiscoverySpotsController を作成。BaseController を継承。index（pending_certification スポット一覧）、certify（認定処理）、reject（却下処理）、merge（統合処理）。before_action :set_contest, :authorize_contest! | Restrictions: 他主催者のコンテストはアクセス拒否 | Success: 審査フローが正しく動作_

- [x] 15. Organizers::DiscoveryChallengesController 作成
  - File: app/controllers/organizers/discovery_challenges_controller.rb
  - CRUD アクション
  - Purpose: 発掘チャレンジのCRUDを処理
  - _Leverage: app/controllers/organizers/spots_controller.rb のパターン_
  - _Requirements: 3（発掘チャレンジ）_
  - _Prompt: Role: Rails Controller Developer | Task: Organizers::DiscoveryChallengesController を作成。BaseController を継承。index, new, create, edit, update, destroy アクション。before_action :set_contest, :set_challenge, :authorize_contest! | Restrictions: 他主催者のコンテストはアクセス拒否 | Success: CRUD 操作が正しく動作_

- [x] 16. SpotVotesController 作成
  - File: app/controllers/spot_votes_controller.rb
  - create, destroy アクション
  - Purpose: スポット投票を処理
  - _Leverage: app/controllers/votes_controller.rb のパターン_
  - _Requirements: 6（隠れた名所投票）_
  - _Prompt: Role: Rails Controller Developer | Task: SpotVotesController を作成。create（投票）、destroy（投票取消）アクション。認証必須、Turbo Stream レスポンス対応 | Restrictions: 認定スポットのみ投票可能 | Success: 投票・取消が正しく動作_

- [x] 17. ルーティング設定
  - File: config/routes.rb
  - organizers namespace に discovery_spots, discovery_challenges リソースを追加
  - spot_votes リソースを追加
  - Purpose: 発掘機能へのルートを定義
  - _Leverage: 既存の organizers namespace ルーティング_
  - _Requirements: All_
  - _Prompt: Role: Rails Developer | Task: config/routes.rb に発掘機能のルーティングを追加。organizers/contests 内に resources :discovery_spots（only: [:index], member: [:certify, :reject, :merge]）、resources :discovery_challenges。resources :spot_votes（only: [:create, :destroy]） | Restrictions: 既存ルートを壊さない | Success: パスヘルパーが利用可能_

- [x] 18. 発掘スポット審査ビュー作成
  - File: app/views/organizers/discovery_spots/index.html.erb
  - 発掘中スポット一覧をカード形式で表示
  - 各スポットに写真、名前、発見者、認定/却下ボタン
  - Purpose: 発掘スポット審査画面の表示
  - _Leverage: app/views/organizers/moderation/index.html.erb のレイアウト_
  - _Requirements: 2（発掘スポット認定）_
  - _Prompt: Role: Rails View Developer | Task: 発掘スポット審査ビューを作成。カード形式で各スポットを表示（写真、名前、場所、発見コメント、発見者名）。認定ボタン、却下ボタン（理由入力モーダル）。Turbo Frame で非同期更新 | Restrictions: Tailwind CSS、既存レイアウトとの整合性 | Success: 審査画面が正しく表示・動作_

- [x] 19. 発掘チャレンジ管理ビュー作成
  - File: app/views/organizers/discovery_challenges/index.html.erb, new.html.erb, edit.html.erb
  - チャレンジ一覧、作成フォーム、編集フォーム
  - Purpose: 発掘チャレンジ管理画面の表示
  - _Leverage: app/views/organizers/spots/ のレイアウト_
  - _Requirements: 3（発掘チャレンジ）_
  - _Prompt: Role: Rails View Developer | Task: 発掘チャレンジ管理ビューを作成。index（チャレンジ一覧、ステータス表示）、new/edit（名前、テーマ、説明、期間のフォーム）。form_with 使用 | Restrictions: Tailwind CSS | Success: CRUD 画面が正しく動作_

- [x] 20. 写真投稿フォームに新規スポット登録オプション追加
  - File: app/views/entries/_form.html.erb, app/controllers/entries_controller.rb
  - 「新規スポットとして登録」チェックボックス追加
  - スポット名、位置、コメント入力フィールド追加
  - コントローラーで DiscoverySpotService 呼び出し
  - Purpose: 参加者が発掘スポットを投稿できるようにする
  - _Leverage: 既存の entries フォーム_
  - _Requirements: 1（発掘スポット投稿）_
  - _Prompt: Role: Rails Full-stack Developer | Task: エントリーフォームに新規スポット登録オプションを追加。「新規スポットとして登録」チェック時にスポット名、地図上での位置選択、発見コメントフィールドを表示。create アクションで DiscoverySpotService.create_discovered_spot を呼び出し | Restrictions: 既存フォームの動作を壊さない | Success: 新規スポット登録が正しく動作_

- [x] 21. 発掘マップ表示機能拡張
  - File: app/views/gallery/map.html.erb, app/controllers/gallery_controller.rb
  - 認定/発掘中/自分の投稿でアイコン色分け
  - 未開拓エリアハイライト表示
  - ヒートマップ切替
  - Purpose: 発掘マップとしての機能を実現
  - _Leverage: 既存の gallery/map ビュー_
  - _Requirements: 4（発掘マップ表示）_
  - _Prompt: Role: Rails Full-stack Developer | Task: ギャラリーマップを発掘マップとして拡張。map_data に discovery_status を追加。フロントエンドでステータス別アイコン色分け。ヒートマップレイヤー追加（Leaflet.heat）。フィルターUI追加（認定のみ/発掘中含む） | Restrictions: 既存マップ機能を壊さない | Success: 発掘マップが正しく表示_

- [x] 22. 発掘マップ Stimulus コントローラー拡張
  - File: app/javascript/controllers/gallery_map_controller.js
  - 既存 map_controller を拡張
  - ステータスフィルター、ヒートマップ切替、未開拓エリア表示
  - Purpose: 発掘マップのインタラクティブ機能を実現
  - _Leverage: 既存の map_controller.js_
  - _Requirements: 4（発掘マップ表示）_
  - _Prompt: Role: Stimulus Developer | Task: gallery_map_controller.js を拡張。connect で Leaflet マップ初期化、マーカー色分け（certified: green, discovered: yellow, mine: blue）。filterByDiscoveryStatus(event) でフィルター | Restrictions: 既存 map_controller との共存 | Success: マップインタラクションが正しく動作_

- [x] 23. スポット投票 UI 追加
  - File: app/views/spots/_vote_button.html.erb, app/views/spot_votes/create.turbo_stream.erb
  - 認定スポットに「いいね」ボタン追加
  - Turbo Stream で非同期更新
  - Purpose: スポット投票のUI実装
  - _Leverage: app/views/votes/ のパターン_
  - _Requirements: 6（隠れた名所投票）_
  - _Prompt: Role: Rails View Developer | Task: スポット投票UIを作成。_vote_button パーシャルに投票/投票済みボタン。button_to で SpotVotesController を呼び出し。Turbo Stream でボタン状態更新 | Restrictions: 既存 votes との整合性 | Success: 投票UIが正しく動作_

- [x] 24. 発掘ランキング表示
  - File: app/views/contests/_discovery_ranking.html.erb, app/controllers/contests_controller.rb
  - 発掘スポット数ランキング
  - 開拓者バッジ保持者表示
  - Purpose: 発掘ランキングの表示
  - _Leverage: app/views/contests/results/ のパターン_
  - _Requirements: 5（発掘ランキング）_
  - _Prompt: Role: Rails View Developer | Task: 発掘ランキングパーシャルを作成。認定スポット数でユーザーランキング表示。開拓者バッジ保持者リスト。DiscoverySpotService.discovery_statistics 使用 | Restrictions: Tailwind CSS | Success: ランキングが正しく表示_

- [x] 25. マイページ発掘実績表示
  - File: app/views/my/profile/_discovery_stats.html.erb
  - 発掘スポット数、認定数、獲得バッジ表示
  - Purpose: ユーザーの発掘実績を表示
  - _Leverage: 既存 my/profile ビュー_
  - _Requirements: 5（発掘ランキング）_
  - _Prompt: Role: Rails View Developer | Task: マイページに発掘実績セクションを追加。認定スポット数、発掘中スポット数、獲得バッジ一覧を表示 | Restrictions: 既存プロフィールレイアウトとの整合性 | Success: 発掘実績が正しく表示_

- [x] 26. 発掘統計ダッシュボード追加
  - File: app/views/organizers/statistics/_discovery.html.erb
  - 発掘スポット総数、エリア別密度、アクティブ発掘者数
  - チャレンジ別参加状況
  - Purpose: 発掘統計の表示
  - _Leverage: 既存 statistics ビュー_
  - _Requirements: 7（発掘統計ダッシュボード）_
  - _Prompt: Role: Rails View Developer | Task: 統計ダッシュボードに発掘セクションを追加。発掘スポット総数（認定/発掘中/却下）、エリア別密度（簡易マップ）、アクティブ発掘者数、チャレンジ別参加状況。DiscoverySpotService.discovery_statistics 使用 | Restrictions: 既存統計レイアウトとの整合性 | Success: 発掘統計が正しく表示_

- [x] 27. サイドメニューに発掘管理リンク追加
  - File: app/views/shared/_sidebar.html.erb
  - 「発掘スポット審査」「発掘チャレンジ」リンク追加
  - Purpose: 発掘管理画面への導線を確保
  - _Leverage: 既存ナビゲーション構造_
  - _Requirements: All_
  - _Prompt: Role: Rails View Developer | Task: 主催者向けサイドメニューに発掘関連リンクを追加。コンテスト詳細配下に「発掘スポット審査」「発掘チャレンジ」リンク | Restrictions: 既存ナビゲーションとの整合性 | Success: リンクが正しく表示・遷移_

- [x] 28. ファクトリー作成
  - File: spec/factories/discovery_challenges.rb, spec/factories/spot_votes.rb, spec/factories/discovery_badges.rb, spec/factories/challenge_entries.rb
  - 各モデル用のファクトリーを作成
  - Purpose: テストデータ生成を容易にする
  - _Leverage: spec/factories/ の既存パターン_
  - _Requirements: All_
  - _Prompt: Role: Rails Test Engineer | Task: 発掘機能用の FactoryBot ファクトリーを作成。discovery_challenges（contest 関連、各ステータス trait）、spot_votes（user, spot 関連）、discovery_badges（user, contest 関連、各バッジタイプ trait）、challenge_entries（discovery_challenge, entry 関連） | Restrictions: 既存ファクトリーとの整合性 | Success: ファクトリーが正しく動作_

- [x] 29. モデルユニットテスト作成
  - File: spec/models/discovery_challenge_spec.rb, spec/models/spot_vote_spec.rb, spec/models/discovery_badge_spec.rb
  - バリデーション、関連、スコープのテスト
  - Purpose: モデルの信頼性を確保
  - _Leverage: spec/models/ の既存テストパターン_
  - _Requirements: All_
  - _Prompt: Role: Rails Test Engineer | Task: 発掘機能モデルのユニットテストを作成。DiscoveryChallenge（バリデーション、期間整合性、ステータス遷移、スコープ）、SpotVote（ユニーク制約、カウンターキャッシュ）、DiscoveryBadge（ユニーク制約、バッジタイプ） | Restrictions: FactoryBot 使用 | Success: 全テスト通過_

- [x] 30. Spot モデルテスト拡張
  - File: spec/models/spot_spec.rb
  - 発掘ステータス、発掘関連スコープのテスト追加
  - Purpose: Spot モデル拡張の信頼性を確保
  - _Leverage: spec/models/spot_spec.rb 既存テスト_
  - _Requirements: 1, 2_
  - _Prompt: Role: Rails Test Engineer | Task: Spot モデルテストに発掘機能のテストを追加。discovery_status enum、discovered_by/certified_by 関連、discovered/certified/pending_certification スコープ | Restrictions: 既存テストを壊さない | Success: 全テスト通過_

- [x] 31. DiscoverySpotService ユニットテスト
  - File: spec/services/discovery_spot_service_spec.rb
  - 各メソッドの正常系・異常系テスト
  - Purpose: サービスクラスの信頼性を確保
  - _Leverage: spec/services/ の既存テストパターン_
  - _Requirements: 1, 2, 7_
  - _Prompt: Role: Rails Test Engineer | Task: DiscoverySpotService のユニットテストを作成。create_discovered_spot（正常、近接スポット警告）、certify_spot（正常、通知送信）、reject_spot（正常、理由必須）、merge_spots、find_nearby_spots、discovery_statistics | Restrictions: FactoryBot 使用 | Success: 全テスト通過_

- [x] 32. コントローラー Request Spec 作成
  - File: spec/requests/organizers/discovery_spots_spec.rb, spec/requests/organizers/discovery_challenges_spec.rb, spec/requests/spot_votes_spec.rb
  - 認証、認可、各アクションのテスト
  - Purpose: コントローラーの動作を検証
  - _Leverage: spec/requests/ の既存パターン_
  - _Requirements: 2, 3, 6_
  - _Prompt: Role: Rails Test Engineer | Task: 発掘機能の Request Spec を作成。DiscoverySpotsController（認証、認可、index/certify/reject）、DiscoveryChallengesController（CRUD）、SpotVotesController（create/destroy、認定スポットのみ） | Restrictions: sign_in ヘルパー使用 | Success: 全テスト通過_

- [x] 33. System Spec 作成
  - File: spec/system/discovery_spec.rb
  - 発掘フロー、チャレンジ参加、投票のE2Eテスト
  - Purpose: E2Eでのユーザー体験を検証
  - _Leverage: spec/system/ の既存テストパターン_
  - _Requirements: All_
  - _Prompt: Role: Rails E2E Test Engineer | Task: 発掘機能の System Spec を作成。参加者が新規スポットを発掘して投稿、主催者が審査・認定、参加者がチャレンジに参加、参加者がスポットに投票、発掘マップ表示 | Restrictions: Capybara 使用、JavaScript 有効化 | Success: E2E テスト通過_
