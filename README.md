# Local Photo Contest

![CI](https://github.com/YukiKudo03/local-photo-contest/actions/workflows/ci.yml/badge.svg)

地域限定フォトコンテスト運営プラットフォーム

## 概要

Local Photo Contest は、市区町村、商店街、観光協会、地域コミュニティなどが主催する地域密着型の写真コンテストを効率的に運営できるWebアプリケーションです。地域の魅力発信や住民参加型イベントとしての写真コンテストを支援します。

## 主な機能

### コンテスト管理
- コンテストの作成・編集・公開・終了
- テーマ設定（地域の風景、祭り、グルメ等）
- 応募期間・審査期間の管理
- コンテストテンプレートによる簡単作成

### 写真投稿・応募
- 写真アップロード（JPEG, PNG, GIF対応、最大10MB）
- 撮影場所の位置情報登録
- 撮影スポットの選択・新規登録
- EXIF情報の自動抽出（撮影日時、GPS座標、カメラ情報）

### 審査・投票システム
- 一般投票機能
- 審査員による評価（複数評価基準設定可能、基準別スコア1〜最大値）
- 審査員招待・管理機能（トークンベース、30日有効）
- 3つのランキング方式: 投票のみ / 審査員のみ / ハイブリッド（重み付け設定可）
- 標準競技ランキング（1224方式）

### ギャラリー・マップ表示
- 応募作品一覧表示（無限スクロール対応）
- 地図上での撮影スポット表示（Leaflet.js + OpenStreetMap）
- コンテスト・カテゴリ・エリア別フィルタリング
- 新着順・人気順・古い順の並び替え

### コンテンツモデレーション
- AWS Rekognitionによる自動画像審査
- 不適切コンテンツの検出・フィルタリング
- 手動承認・却下ワークフロー（Turbo Stream対応）
- コンテスト単位での閾値設定

### 発見チャレンジ機能
- 隠れスポット発見チャレンジ
- スポットの認定・却下ワークフロー
- スポット投票機能
- バッジ獲得（Explorer: 5+スポット発見、Curator: 10+スポット認定）
- 近隣スポット検索（Haversine距離計算、50m半径）
- スポット統合（マージ）機能

### 統計・分析
- 応募数推移グラフ（日次・週次）
- エリア別応募分布
- 投票分析ダッシュボード
- 日付範囲フィルタリング（プリセット: 直近7日/30日/今週/今月）
- CSV エクスポート（日次統計・概要・エントリー詳細・スポット）
- 5分間のRedisキャッシュ

### 通知・メール
- リアルタイム通知（Action Cable）
- 9種類のメール通知（応募確認、コメント、投票、結果発表、入賞、審査リマインダー等）
- 日次ダイジェストメール
- ユーザー別メール配信設定（6項目）
- トークンベースのワンクリック配信停止

### 検索機能
- コンテスト・応募作品・スポットの横断検索
- 全文検索（PostgreSQL: ILIKE / SQLite: LIKE）
- タイプ別フィルタリング

### チュートリアル・ヘルプ
- 初回ログイン時のステップバイステップチュートリアル
- ロール別チュートリアル（参加者・主催者・審査員）
- アプリ内ヘルプページ（Markdownレンダリング、目次付き）
- コンテキストヘルプ・アニメーション設定

### 多言語対応（i18n）
- 日本語・英語完全対応
- ユーザー単位のロケール設定・保存
- フッターからのワンクリック言語切替
- メールのロケール対応

### その他
- コメント機能
- SNS共有機能
- 監査ログ
- PWA対応（Service Worker、オフラインフォールバック）
- レート制限（Rack::Attack）
- エラー監視（Sentry）

## 技術スタック

- **フレームワーク**: Ruby on Rails 8.0
- **Ruby バージョン**: 3.4.x
- **フロントエンド**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **認証**: Devise
- **データベース**: SQLite (開発) / PostgreSQL (Docker・本番)
- **画像処理**: Active Storage, MiniMagick
- **リアルタイム通信**: Action Cable (Solid Cable)
- **バックグラウンドジョブ**: Solid Queue
- **キャッシュ**: Solid Cache, Redis
- **グラフ**: Chartkick + Chart.js
- **地図**: Leaflet.js + OpenStreetMap
- **Markdown**: Redcarpet + Rouge
- **レート制限**: Rack::Attack
- **テスト**: RSpec, FactoryBot, Shoulda Matchers, Capybara, SimpleCov
- **コード品質**: RuboCop, Brakeman, Bullet (N+1検出)
- **デプロイ**: Docker, Kamal

## セットアップ

### 必要環境

- Ruby 3.4.x
- Bundler
- ImageMagick

### ローカル開発（SQLite）

```bash
# リポジトリのクローン
git clone <repository-url>
cd local-photo-contest

# 依存関係のインストール
bundle install

# データベースのセットアップ
bin/rails db:create db:migrate db:seed

# サーバー起動
bin/dev
```

### Docker開発

```bash
# コンテナのビルドと起動
docker compose up -d

# データベースのセットアップ
docker compose exec web rails db:create db:migrate db:seed

# ログの確認
docker compose logs -f web
```

### 環境変数

Docker環境では以下の環境変数を設定できます（`.env`ファイル）：

```bash
# データベース
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=local_photo_contest_development

# AWS Rekognition（コンテンツモデレーション用・任意）
AWS_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# モデレーション設定
MODERATION_ENABLED=true
MODERATION_PROVIDER=rekognition
MODERATION_THRESHOLD=60.0

# Sentry（エラー監視・任意）
SENTRY_DSN=your_sentry_dsn

# Redis（キャッシュ・任意）
REDIS_URL=redis://localhost:6379/0
```

## 開発用アカウント

シードデータにより以下のテストアカウントが作成されます：

| 権限 | メールアドレス | パスワード |
|------|---------------|-----------|
| 運営者 | organizer@example.com | password123 |
| 管理者 | admin@example.com | password123 |

## URL構成

### 一般ユーザー向け

| パス | 説明 |
|------|------|
| `/` | ホームページ |
| `/contests` | コンテスト一覧 |
| `/contests/:id` | コンテスト詳細 |
| `/contests/:id/results` | コンテスト結果 |
| `/gallery` | ギャラリー |
| `/gallery/map` | マップ表示 |
| `/search` | 横断検索 |
| `/help` | ヘルプセンター |
| `/help/:guide` | ガイド（participant / organizer / judge / admin） |

### 参加者向け（ログイン後）

| パス | 説明 |
|------|------|
| `/my/entries` | 自分の応募作品 |
| `/my/votes` | 自分の投票履歴 |
| `/my/notifications` | 通知一覧 |
| `/my/profile` | プロフィール |
| `/my/tutorial_settings` | チュートリアル設定 |
| `/my/judge_assignments` | 審査員ダッシュボード |

### 運営者向け

| パス | 説明 |
|------|------|
| `/organizers/sign_in` | 運営者ログイン |
| `/organizers/sign_up` | 運営者登録 |
| `/organizers/dashboard` | 運営者ダッシュボード |
| `/organizers/contests` | コンテスト管理 |
| `/organizers/areas` | エリア管理 |
| `/organizers/contest_templates` | テンプレート管理 |
| `/organizers/contests/:id/statistics` | 統計ダッシュボード |
| `/organizers/contests/:id/moderation` | モデレーション管理 |
| `/organizers/contests/:id/spots` | スポット管理 |
| `/organizers/contests/:id/discovery_spots` | 発見スポット管理 |
| `/organizers/contests/:id/discovery_challenges` | チャレンジ管理 |

### 管理者向け

| パス | 説明 |
|------|------|
| `/admin/dashboard` | 管理者ダッシュボード |
| `/admin/users` | ユーザー管理 |
| `/admin/contests` | 全コンテスト管理 |
| `/admin/categories` | カテゴリ管理 |
| `/admin/audit_logs` | 監査ログ |
| `/admin/tutorial_analytics` | チュートリアル分析 |

## テスト

```bash
# 全テスト実行
bundle exec rspec

# 特定のテスト実行
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
bundle exec rspec spec/system/
bundle exec rspec spec/services/

# カバレッジ付きで実行
COVERAGE=true bundle exec rspec
# レポート: coverage/index.html
```

## コード品質

```bash
# RuboCop（静的解析・フォーマット）
bundle exec rubocop

# 自動修正
bundle exec rubocop -a

# Brakeman（セキュリティスキャン）
bundle exec brakeman
```

## ディレクトリ構成

```
app/
├── channels/
│   ├── contest_channel.rb        # コンテストリアルタイム更新
│   ├── entry_channel.rb          # エントリー投票リアルタイム更新
│   └── notifications_channel.rb  # ユーザー通知
├── controllers/
│   ├── admin/                    # 管理者機能
│   ├── concerns/                 # 共通Concern
│   ├── contests/                 # コンテスト結果
│   ├── gallery/                  # マップコントローラー
│   ├── my/                       # ユーザー個人機能
│   └── organizers/               # 運営者機能
├── jobs/
│   ├── daily_digest_job.rb       # 日次ダイジェストメール
│   ├── exif_extraction_job.rb    # EXIF情報抽出
│   ├── judging_deadline_job.rb   # 審査締め切り通知
│   ├── judging_reminder_job.rb   # 審査リマインダー
│   └── moderation_job.rb         # 画像モデレーション
├── mailers/
│   ├── judge_invitation_mailer.rb
│   └── notification_mailer.rb    # 9種類のメール通知
├── models/
│   ├── concerns/
│   │   ├── contest_state_machine.rb  # コンテスト状態遷移
│   │   ├── entry_notifications.rb    # エントリー通知コールバック
│   │   ├── moderatable.rb            # モデレーション機能
│   │   ├── searchable.rb             # 全文検索
│   │   └── tutorial_trackable.rb     # チュートリアル追跡
│   └── ...                       # 29モデル
├── services/
│   ├── admin/                    # 管理者統計
│   ├── moderation/               # コンテンツモデレーション
│   │   ├── moderation_service.rb
│   │   ├── providers.rb
│   │   └── providers/            # AWS Rekognition等
│   ├── ranking_strategies/       # ランキング計算戦略
│   │   ├── base_strategy.rb
│   │   ├── hybrid_strategy.rb
│   │   ├── judge_only_strategy.rb
│   │   └── vote_only_strategy.rb
│   ├── discovery_spot_service.rb
│   ├── entry_filter_service.rb   # 共通フィルターロジック
│   ├── map_marker_service.rb
│   ├── notification_broadcaster.rb
│   ├── ranking_calculator.rb
│   ├── statistics_service.rb
│   ├── statistics_export_service.rb
│   └── ...
└── views/

config/
├── locales/                      # i18n（日本語・英語、57ファイル）
├── routes.rb
└── ...

spec/
├── factories/                    # FactoryBot
├── models/
├── requests/
├── services/
└── system/                       # システムテスト（Capybara）
```

## 設定値

### Devise設定

| 設定項目 | 値 |
|---------|-----|
| パスワード最小長 | 8文字 |
| ロック方式 | 失敗回数 (5回) |
| ロック解除時間 | 30分 |
| メール確認期限 | 24時間 |
| パスワードリセット期限 | 6時間 |
| ログイン状態保持期間 | 2週間 |
| セッションタイムアウト | 24時間 |

### 権限

| 権限 | 説明 |
|------|------|
| participant | 一般参加者（デフォルト） |
| organizer | 運営者（コンテスト作成・管理） |
| admin | 管理者（全機能アクセス） |

## デプロイ

### Docker本番環境

```bash
# イメージのビルド
docker build -t local-photo-contest .

# Kamalでデプロイ
bin/kamal deploy
```

### Heroku

```bash
heroku create
heroku addons:create heroku-postgresql:mini
git push heroku main
heroku run rails db:migrate db:seed
```

## ライセンス

MIT License

## 作者

Local Photo Contest Team
