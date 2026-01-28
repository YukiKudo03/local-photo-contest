# Tasks Document: Statistics Dashboard

- [x] 1. Chartkick + Chart.js セットアップ
  - File: Gemfile, config/importmap.rb, app/javascript/application.js
  - Gemfile に chartkick gem を追加
  - importmap で Chart.js と Chartkick をピン
  - application.js で Chartkick をインポート
  - Purpose: グラフ描画ライブラリの基盤を構築
  - _Leverage: 既存の importmap 設定_
  - _Requirements: All（グラフ表示の基盤）_
  - _Prompt: Role: Rails Developer | Task: Chartkick と Chart.js を Rails 8 アプリケーションにセットアップ。Gemfile に gem "chartkick" を追加し、config/importmap.rb で Chart.js と Chartkick をピン、app/javascript/application.js でインポートを設定 | Restrictions: 既存の importmap 設定を壊さない、bundle install と importmap:pin を実行 | Success: Chartkick ヘルパーがビューで使用可能、グラフが正常にレンダリングされる_

- [x] 2. StatisticsService 基本実装
  - File: app/services/statistics_service.rb
  - StatisticsService クラスを作成
  - initialize(contest) でコンテストを受け取る
  - summary_stats メソッドでサマリーデータを返す
  - Purpose: 統計計算ロジックの基盤を構築
  - _Leverage: app/services/ranking_calculator.rb のパターン_
  - _Requirements: 4（サマリーカード）_
  - _Prompt: Role: Rails Backend Developer | Task: StatisticsService クラスを作成。initialize(contest) でコンテストを受け取り、summary_stats メソッドで総応募数、総投票数、参加ユーザー数、登録スポット数、および前日比を計算して返す | Restrictions: N+1 クエリを避ける、ActiveRecord の集計メソッドを活用 | Success: summary_stats が正しいハッシュを返す、パフォーマンスが良好_

- [x] 3. StatisticsService 応募数推移メソッド
  - File: app/services/statistics_service.rb（継続）
  - daily_entries メソッドで日別応募数を返す
  - weekly_entries メソッドで週別応募数を返す
  - Chartkick 対応形式（Hash: Date => Integer）で返す
  - Purpose: 応募数推移グラフ用データを提供
  - _Leverage: Entry モデルの created_at_
  - _Requirements: 1（応募数推移グラフ）_
  - _Prompt: Role: Rails Backend Developer | Task: StatisticsService に daily_entries と weekly_entries メソッドを追加。日別・週別の応募数を Chartkick 対応形式（{ Date => count }）で返す。7日以上の場合は週単位オプションを提供 | Restrictions: SQL レベルでグループ集計、タイムゾーン考慮 | Success: グラフ表示に適したデータ形式、日本時間での日付集計_

- [x] 4. StatisticsService スポット分析メソッド
  - File: app/services/statistics_service.rb（継続）
  - spot_rankings(limit:) メソッドでスポット別ランキングを返す
  - area_distribution メソッドでエリア別分布を返す
  - スポット未指定も「スポット未指定」としてカウント
  - Purpose: 人気スポット分析用データを提供
  - _Leverage: Entry モデルの spot 関連、Spot モデル_
  - _Requirements: 2（人気スポット分析）_
  - _Prompt: Role: Rails Backend Developer | Task: StatisticsService に spot_rankings(limit: 10) と area_distribution メソッドを追加。スポット別応募数を降順で返す、スポット未指定は「スポット未指定」としてカウント。エリア別応募分布も計算 | Restrictions: includes でN+1防止、nil スポットの適切な処理 | Success: 上位10件のスポットランキング、エリア別円グラフ用データ_

- [x] 5. StatisticsService 投票分析メソッド
  - File: app/services/statistics_service.rb（継続）
  - daily_votes メソッドで日別投票数を返す
  - vote_summary メソッドで投票サマリーを返す
  - top_voted_entries(limit:) メソッドで上位得票作品を返す
  - Purpose: 投票分析用データを提供
  - _Leverage: Vote モデル、Entry モデルの votes 関連_
  - _Requirements: 3（投票分析）_
  - _Prompt: Role: Rails Backend Developer | Task: StatisticsService に daily_votes、vote_summary（総投票数、ユニーク投票者数、平均投票数/作品）、top_voted_entries(limit: 5) メソッドを追加 | Restrictions: distinct で重複除去、適切な includes | Success: 投票推移グラフ用データ、投票サマリー、上位5作品リスト_

- [x] 6. StatisticsService ユニットテスト
  - File: spec/services/statistics_service_spec.rb
  - 各メソッドのユニットテストを作成
  - 空データ、正常データ、大量データのケースをカバー
  - 前日比計算のテスト
  - Purpose: サービスクラスの信頼性を確保
  - _Leverage: spec/services/ の既存テストパターン、FactoryBot_
  - _Requirements: All_
  - _Prompt: Role: Rails Test Engineer | Task: StatisticsService の包括的なユニットテストを作成。summary_stats、daily_entries、spot_rankings、vote_summary 等の各メソッドをテスト。空データ、1件、複数件、前日比計算をカバー | Restrictions: FactoryBot 使用、テストデータは明示的に作成 | Success: 全メソッドのテストカバレッジ、エッジケース対応_

- [x] 7. Organizers::StatisticsController 作成
  - File: app/controllers/organizers/statistics_controller.rb
  - Organizers::BaseController を継承
  - show アクションで統計ダッシュボードを表示
  - before_action で set_contest、authorize_contest を実装
  - Purpose: 統計ダッシュボードのリクエスト処理
  - _Leverage: app/controllers/organizers/base_controller.rb、app/controllers/organizers/results_controller.rb_
  - _Requirements: 5（アクセス制御）_
  - _Prompt: Role: Rails Controller Developer | Task: Organizers::StatisticsController を作成。BaseController を継承し、show アクションで StatisticsService を使用してデータを取得。set_contest と owned_by? でアクセス制御 | Restrictions: 他主催者のコンテストはアクセス拒否、適切なリダイレクト | Success: 認証・認可が機能、StatisticsService のデータがビューに渡る_

- [x] 8. ルーティング設定
  - File: config/routes.rb
  - organizers 名前空間に statistics リソースを追加
  - GET /organizers/contests/:contest_id/statistics
  - Purpose: 統計ダッシュボードへのルートを定義
  - _Leverage: 既存の organizers namespace ルーティング_
  - _Requirements: 5（アクセス制御 - URL構造）_
  - _Prompt: Role: Rails Developer | Task: config/routes.rb の organizers namespace 内に resource :statistics, only: [:show] を追加 | Restrictions: 既存ルートを壊さない | Success: organizers_contest_statistics_path ヘルパーが利用可能_

- [x] 9. サマリーカードパーシャル作成
  - File: app/views/organizers/statistics/_summary_cards.html.erb
  - 総応募数、総投票数、参加ユーザー数、登録スポット数を表示
  - 前日比の増減を表示（+5件 など）
  - 0件の場合も適切に表示
  - Purpose: 主要指標の一覧表示
  - _Leverage: app/views/organizers/results/preview.html.erb のカードデザイン_
  - _Requirements: 4（サマリーカード）_
  - _Prompt: Role: Rails View Developer | Task: サマリーカードパーシャルを作成。4つの指標（応募数、投票数、参加者数、スポット数）をカード形式で表示。前日比は緑（増加）/赤（減少）で表示 | Restrictions: Tailwind CSS 使用、レスポンシブ対応 | Success: 4つのカードが横並び、前日比が視覚的に分かりやすい_

- [x] 10. 応募数推移グラフパーシャル作成
  - File: app/views/organizers/statistics/_entry_trend_chart.html.erb
  - Chartkick の line_chart で日別応募数を表示
  - データがない場合は「まだデータがありません」を表示
  - ツールチップで正確な応募数を表示
  - Purpose: 応募数の時系列推移を可視化
  - _Leverage: Chartkick ヘルパー_
  - _Requirements: 1（応募数推移グラフ）_
  - _Prompt: Role: Rails View Developer with Chartkick | Task: line_chart を使用して日別応募数推移グラフを作成。データがない場合のフォールバック表示、ツールチップ設定、日本語ラベル | Restrictions: Chartkick + Chart.js のみ使用 | Success: 折れ線グラフが表示、ホバーでツールチップ、空データ時のメッセージ_

- [x] 11. スポット別グラフパーシャル作成
  - File: app/views/organizers/statistics/_spot_chart.html.erb
  - Chartkick の bar_chart でスポット別応募数を表示（上位10件）
  - クリックで応募一覧へ遷移するリンクを追加
  - Purpose: 人気スポットの可視化
  - _Leverage: Chartkick ヘルパー_
  - _Requirements: 2（人気スポット分析）_
  - _Prompt: Role: Rails View Developer with Chartkick | Task: bar_chart を使用してスポット別応募数を横棒グラフで表示。上位10件、降順ソート。各バーの下にスポット別応募一覧へのリンクを追加 | Restrictions: 横棒グラフ推奨、クリック遷移は別途リンクで対応 | Success: 棒グラフが表示、スポット名とカウントが明確_

- [x] 12. エリア別円グラフパーシャル作成
  - File: app/views/organizers/statistics/_area_pie_chart.html.erb
  - Chartkick の pie_chart でエリア別応募分布を表示
  - エリア未設定の場合は非表示またはメッセージ
  - Purpose: エリア別の応募分布を可視化
  - _Leverage: Chartkick ヘルパー_
  - _Requirements: 2.5（エリア別応募数円グラフ）_
  - _Prompt: Role: Rails View Developer with Chartkick | Task: pie_chart を使用してエリア別応募分布を円グラフで表示。エリアが設定されていない場合は「エリア情報がありません」を表示 | Restrictions: Chartkick pie_chart 使用 | Success: 円グラフが表示、エリア名と割合が明確_

- [x] 13. 投票分析パーシャル作成
  - File: app/views/organizers/statistics/_vote_analysis.html.erb
  - 投票数推移グラフ（line_chart）
  - 投票サマリー（総投票数、ユニーク投票者数、平均投票数/作品）
  - 上位得票作品リスト（Top 5）
  - 投票期間開始前メッセージ
  - Purpose: 投票状況の包括的な分析表示
  - _Leverage: Chartkick ヘルパー_
  - _Requirements: 3（投票分析）_
  - _Prompt: Role: Rails View Developer | Task: 投票分析セクションを作成。日別投票推移グラフ、投票サマリーカード、上位5作品リスト。投票期間開始前は「投票期間開始後に表示されます」を表示 | Restrictions: 投票がない場合のフォールバック対応 | Success: 投票グラフ、サマリー、Top5リストが正しく表示_

- [x] 14. 統計ダッシュボードメインビュー作成
  - File: app/views/organizers/statistics/show.html.erb
  - 全パーシャルを組み合わせてダッシュボードを構成
  - セクション分けとナビゲーション
  - レスポンシブレイアウト
  - Purpose: 統計ダッシュボードの完成
  - _Leverage: app/views/organizers/results/preview.html.erb のレイアウト_
  - _Requirements: All_
  - _Prompt: Role: Rails View Developer | Task: 統計ダッシュボードのメインビューを作成。サマリーカード、応募推移、スポット分析、投票分析の各セクションを配置。コンテスト詳細へのリンク、レスポンシブグリッド | Restrictions: Tailwind CSS、既存レイアウトとの整合性 | Success: 全セクションが適切に配置、モバイル対応_

- [x] 15. コントローラー Request Spec 作成
  - File: spec/requests/organizers/statistics_spec.rb
  - 認証なしアクセス → リダイレクト
  - 他主催者のコンテストアクセス → アクセス拒否
  - 正常アクセス → 200レスポンス
  - データありでのビュー確認
  - Purpose: コントローラーの動作を検証
  - _Leverage: spec/requests/organizers/results_spec.rb のパターン_
  - _Requirements: 5（アクセス制御）_
  - _Prompt: Role: Rails Test Engineer | Task: Organizers::StatisticsController の Request Spec を作成。認証なし、他主催者、正常アクセスのケースをテスト。レスポンスステータスとリダイレクト先を検証 | Restrictions: sign_in ヘルパー使用、FactoryBot でデータ作成 | Success: 全アクセス制御パターンのテスト通過_

- [x] 16. System Spec 作成
  - File: spec/system/organizers/statistics_spec.rb
  - 主催者がダッシュボードにアクセスしてグラフが表示される
  - サマリーカードに正しい数値が表示される
  - データがない場合の表示確認
  - Purpose: E2Eでのユーザー体験を検証
  - _Leverage: spec/system/ の既存テストパターン_
  - _Requirements: All_
  - _Prompt: Role: Rails E2E Test Engineer | Task: 統計ダッシュボードの System Spec を作成。主催者ログイン → ダッシュボードアクセス → グラフ表示確認 → サマリー数値確認のフローをテスト | Restrictions: Capybara 使用、JavaScript 有効化 | Success: E2Eテスト通過、ユーザー体験が検証済み_

- [x] 17. ナビゲーションリンク追加
  - File: app/views/organizers/contests/show.html.erb
  - コンテスト詳細ページに「統計ダッシュボード」へのリンクを追加
  - 適切な位置にボタン/リンクを配置
  - Purpose: 統計ダッシュボードへの導線を確保
  - _Leverage: 既存のコンテスト詳細ページレイアウト_
  - _Requirements: All（アクセス導線）_
  - _Prompt: Role: Rails View Developer | Task: コンテスト詳細ページ（organizers/contests/show）に「統計ダッシュボード」へのリンクを追加。既存のボタン群に統合 | Restrictions: 既存レイアウトとの整合性 | Success: リンクが適切な位置に表示、遷移が正常_
