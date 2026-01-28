# Local Photo Contest

地域限定フォトコンテスト運営プラットフォーム

## 概要

Local Photo Contest は、市区町村、商店街、観光協会、地域コミュニティなどが主催する地域密着型の写真コンテストを効率的に運営できるWebアプリケーションです。地域の魅力発信や住民参加型イベントとしての写真コンテストを支援します。

## 主な機能

### コンテスト管理
- コンテストの作成・編集・公開
- テーマ設定（地域の風景、祭り、グルメ等）
- 応募期間・審査期間の管理
- コンテストテンプレートによる簡単作成

### 写真投稿・応募
- 写真アップロード（JPEG, PNG, WebP対応）
- 撮影場所の位置情報登録
- 撮影スポットの選択・新規登録

### 審査・投票システム
- 一般投票機能
- 審査員による評価（複数評価基準設定可能）
- 審査員招待・管理機能
- ハイブリッドランキング（投票+審査員評価の組み合わせ）

### ギャラリー・マップ表示
- 応募作品一覧表示
- 地図上での撮影スポット表示
- スポット別作品閲覧

### コンテンツモデレーション
- AWS Rekognitionによる自動画像審査
- 不適切コンテンツの検出・フィルタリング
- 手動承認・却下ワークフロー

### 発見チャレンジ機能
- 隠れスポット発見チャレンジ
- スポット認定・バッジ獲得

### 統計・分析
- 応募数推移グラフ
- エリア別応募分布
- 投票分析ダッシュボード

### その他
- リアルタイム通知（Action Cable）
- コメント機能
- SNS共有機能
- 監査ログ

## 技術スタック

- **フレームワーク**: Ruby on Rails 8.0
- **フロントエンド**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **認証**: Devise
- **データベース**: SQLite (開発) / PostgreSQL (Docker・本番)
- **画像処理**: Active Storage, ImageMagick / libvips
- **リアルタイム通信**: Action Cable
- **バックグラウンドジョブ**: Solid Queue
- **キャッシュ**: Solid Cache
- **グラフ**: Chartkick + Chart.js
- **地図**: Leaflet.js + OpenStreetMap
- **テスト**: RSpec, FactoryBot, Shoulda Matchers, Capybara
- **デプロイ**: Docker, Kamal

## セットアップ

### 必要環境

- Ruby 3.3+
- Bundler
- ImageMagick または libvips

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
| `/gallery` | ギャラリー |
| `/gallery/map` | マップ表示 |

### 参加者向け（ログイン後）

| パス | 説明 |
|------|------|
| `/my/entries` | 自分の応募作品 |
| `/my/votes` | 自分の投票履歴 |
| `/my/notifications` | 通知一覧 |
| `/my/profile` | プロフィール |
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

### 管理者向け

| パス | 説明 |
|------|------|
| `/admin/dashboard` | 管理者ダッシュボード |
| `/admin/users` | ユーザー管理 |
| `/admin/contests` | 全コンテスト管理 |
| `/admin/categories` | カテゴリ管理 |
| `/admin/audit_logs` | 監査ログ |

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
├── controllers/
│   ├── admin/              # 管理者機能
│   ├── concerns/           # 共通Concern
│   ├── my/                 # ユーザー個人機能
│   └── organizers/         # 運営者機能
├── models/
│   ├── area.rb             # エリア
│   ├── contest.rb          # コンテスト
│   ├── entry.rb            # 応募作品
│   ├── spot.rb             # 撮影スポット
│   ├── vote.rb             # 投票
│   └── ...
├── services/
│   ├── moderation/         # コンテンツモデレーション
│   ├── ranking_calculator.rb
│   ├── statistics_service.rb
│   └── ...
├── views/
│   ├── admin/
│   ├── contests/
│   ├── gallery/
│   ├── organizers/
│   └── ...
└── javascript/
    └── controllers/        # Stimulus コントローラー

config/
├── locales/                # 日本語化ファイル
├── routes.rb
└── ...

spec/
├── factories/              # FactoryBot
├── models/
├── requests/
├── services/
└── system/                 # システムテスト
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
