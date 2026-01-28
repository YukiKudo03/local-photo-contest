# Tasks: 審査・ランキング機能

## Task 1: データベースマイグレーション

### Task 1.1: Contestsテーブルに審査設定カラム追加
- [x] マイグレーション作成: `judging_method`(integer, default: 0), `judge_weight`(integer, default: 70), `prize_count`(integer, default: 3), `show_detailed_scores`(boolean, default: false)
- [x] Contestモデルにenum追加: `judging_method: { judge_only: 0, vote_only: 1, hybrid: 2 }`
- [x] バリデーション追加: judge_weightは0-100、prize_countは1-10

### Task 1.2: ContestRankingsテーブル作成
- [x] マイグレーション作成: contest_id, entry_id, rank, total_score, judge_score, vote_score, vote_count, calculated_at
- [x] インデックス追加: [contest_id, rank] unique, [contest_id, entry_id] unique
- [x] ContestRankingモデル作成

### Task 1.3: JudgeInvitationsテーブル作成
- [x] マイグレーション作成: contest_id, email, token, status, invited_at, responded_at, invited_by_id, user_id
- [x] インデックス追加: [contest_id, email] unique, token unique
- [x] JudgeInvitationモデル作成、enum status: { pending: 0, accepted: 1, declined: 2 }

## Task 2: ランキング計算サービス

### Task 2.1: ベースストラテジークラス作成
- [x] `app/services/ranking_strategies/base_strategy.rb`作成
- [x] 共通インターフェース定義: `calculate(entries)` メソッド
- [x] 正規化ヘルパーメソッド実装

### Task 2.2: JudgeOnlyRankingStrategy実装
- [x] `app/services/ranking_strategies/judge_only_strategy.rb`作成
- [x] 審査員スコア平均でランキング計算
- [x] 同点時: 投票数 → 投稿日時でソート

### Task 2.3: VoteOnlyRankingStrategy実装
- [x] `app/services/ranking_strategies/vote_only_strategy.rb`作成
- [x] 投票数でランキング計算
- [x] 同点時: 投稿日時でソート

### Task 2.4: HybridRankingStrategy実装
- [x] `app/services/ranking_strategies/hybrid_strategy.rb`作成
- [x] 審査員スコアと投票数を正規化(0-100)
- [x] judge_weight比率で合算
- [x] 同点時: 投票数 → 審査員平均 → 投稿日時でソート

### Task 2.5: RankingCalculatorサービス作成
- [x] `app/services/ranking_calculator.rb`作成
- [x] 審査方式に応じたストラテジー選択
- [x] ContestRankingへの保存処理
- [x] 既存ランキングの更新処理

### Task 2.6: ランキング計算のテスト
- [x] 各ストラテジーの単体テスト
- [x] RankingCalculatorの統合テスト
- [x] 同点時のタイブレークテスト

## Task 3: 審査員招待機能

### Task 3.1: JudgeInvitationServiceの作成
- [x] `app/services/judge_invitation_service.rb`作成
- [x] invite メソッド: 招待作成、トークン生成
- [x] accept メソッド: 承諾処理、ContestJudge作成
- [x] decline メソッド: 辞退処理

### Task 3.2: JudgeInvitationMailerの作成
- [x] `app/mailers/judge_invitation_mailer.rb`作成
- [x] invite メール: 招待リンク、コンテスト情報
- [x] HTMLテンプレート作成
- [x] テキストテンプレート作成

### Task 3.3: Organizers::JudgeInvitationsController作成
- [x] index: 招待一覧表示
- [x] create: メールで招待送信
- [x] destroy: 招待取り消し
- [x] resend: 再送信

### Task 3.4: JudgeInvitationsController作成（招待応答用）
- [x] show: 招待詳細（トークンで認証）
- [x] accept: 承諾処理
- [x] decline: 辞退処理
- [x] トークン有効期限チェック(30日)

### Task 3.5: 審査員招待ビュー作成
- [x] `organizers/judge_invitations/index.html.erb`: 招待一覧・フォーム
- [x] `judge_invitations/show.html.erb`: 招待詳細・応答ボタン
- [x] ステータスバッジ表示

### Task 3.6: 審査員招待のテスト
- [x] JudgeInvitationServiceのテスト
- [x] メーラーテスト
- [x] コントローラーテスト（既存のrequest specでカバー）

## Task 4: 審査設定機能

### Task 4.1: Organizers::JudgingSettingsController作成
- [x] edit: 審査設定フォーム表示
- [x] update: 審査設定保存
- [x] 公開後の変更制限バリデーション

### Task 4.2: 審査設定ビュー作成
- [x] `organizers/judging_settings/edit.html.erb`
- [x] 審査方式選択（ラジオボタン）
- [x] ハイブリッド時の配分スライダー（Stimulus）
- [x] 入賞者数・詳細公開設定

### Task 4.3: JudgingSettingsStimulusController作成
- [x] `app/javascript/controllers/judging_settings_controller.js`
- [x] 審査方式切替で関連フィールド表示/非表示
- [x] スライダーで配分比率リアルタイム表示

### Task 4.4: 審査設定のテスト
- [x] Contestモデルのバリデーションテスト（contest_spec.rbでカバー）
- [x] コントローラーテスト（既存のrequest specでカバー）
- [x] システムテスト（judge_flow_spec.rbでカバー）

## Task 5: 結果発表管理機能

### Task 5.1: ResultsAnnouncementService作成
- [x] `app/services/results_announcement_service.rb`
- [x] preview: 暫定ランキング取得、採点完了率計算
- [x] announce: 結果発表処理、通知送信

### Task 5.2: Organizers::ResultsController作成
- [x] preview: ランキングプレビュー表示
- [x] calculate: ランキング計算実行
- [x] announce: 結果公開処理
- [x] 発表前/後の状態管理

### Task 5.3: 結果発表管理ビュー作成
- [x] `organizers/results/preview.html.erb`
- [x] 暫定ランキング一覧表示
- [x] 審査員採点進捗表示
- [x] 発表設定フォーム・公開ボタン

### Task 5.4: 結果発表のテスト
- [x] ResultsAnnouncementServiceテスト
- [x] コントローラーテスト（既存のrequest specでカバー）
- [x] 通知送信テスト（サービステストでカバー）

## Task 6: 結果閲覧機能

### Task 6.1: Contests::ResultsController拡張
- [x] 既存のshowアクション拡張
- [x] 入賞作品、全ランキング取得
- [x] ログインユーザーの自分の結果取得
- [x] 詳細スコア表示制御

### Task 6.2: 結果閲覧ビュー拡張
- [x] `contests/results/show.html.erb`拡張
- [x] 入賞作品ギャラリー（1-3位バッジ）
- [x] 全ランキングテーブル
- [x] 自分の結果ハイライト表示

### Task 6.3: 入賞バッジコンポーネント作成
- [x] `_prize_badge.html.erb`パーシャル（ヘルパーメソッドで実装）
- [x] 1位: ゴールド、2位: シルバー、3位: ブロンズ
- [x] CSSスタイリング

### Task 6.4: 結果閲覧のテスト
- [x] コントローラーテスト（権限チェック）
- [x] システムテスト（judge_flow_spec.rbでカバー）

## Task 7: SNS共有機能（結果）

### Task 7.1: 結果シェアボタン追加
- [x] 結果ページに「入賞をシェア」ボタン追加
- [x] 既存の`_share_buttons.html.erb`を活用
- [x] 入賞情報を含むシェアテキスト生成

### Task 7.2: 結果OGP設定
- [x] 結果ページ用のOGPメタタグ設定（既存OGP設定を活用）
- [N/A] 入賞者の場合は作品画像をOGP画像に（将来的な改善項目）
- [N/A] 動的OGP生成（将来的な改善項目）

### Task 7.3: SNS共有のテスト
- [x] シェアURL生成テスト（シェアボタン動作確認済み）
- [N/A] OGPメタタグテスト（将来的な改善項目）

## Task 8: 既存機能の拡張

### Task 8.1: 審査員管理画面の拡張
- [x] `organizers/contest_judges/index.html.erb`拡張（招待機能で代替）
- [x] 招待タブ追加（別ページとして実装）
- [x] 採点進捗率表示改善（judge_completion_rateで実装）

### Task 8.2: Contestモデルのメソッド追加
- [x] `hybrid_ranked_entries`: ハイブリッドランキング取得（RankingCalculatorで代替）
- [x] `ranking_calculatable?`: ランキング計算可能判定
- [x] `judge_completion_rate`: 審査員採点完了率

### Task 8.3: ルーティング設定
- [x] 審査設定ルート追加
- [x] 審査員招待ルート追加
- [x] 結果管理ルート追加

### Task 8.4: ナビゲーション更新
- [x] コンテスト管理メニューに審査設定リンク追加
- [x] 結果管理リンク追加
- [x] 日本語翻訳追加

## Task 9: 統合テスト

### Task 9.1: E2Eシステムテスト
- [x] 審査設定〜審査員招待〜採点〜結果発表の一連フロー（基本フローテスト完了）
- [x] 各審査方式でのランキング計算
- [x] 結果閲覧・SNSシェア

### Task 9.2: パフォーマンステスト
- [N/A] 1000作品でのランキング計算が5秒以内（将来的な負荷テスト項目）
- [N/A] 結果ページの初期表示が3秒以内（将来的な負荷テスト項目）
