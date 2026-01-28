# Heroku デプロイ手順書

このガイドでは、Local Photo Contest を Heroku にデプロイする手順を説明します。

---

## 目次

1. [前提条件](#前提条件)
2. [事前準備](#事前準備)
3. [Heroku アプリの作成](#heroku-アプリの作成)
4. [アドオンの設定](#アドオンの設定)
5. [環境変数の設定](#環境変数の設定)
6. [AWS S3 の設定](#aws-s3-の設定)
7. [デプロイ](#デプロイ)
8. [デプロイ後の設定](#デプロイ後の設定)
9. [運用コマンド](#運用コマンド)
10. [トラブルシューティング](#トラブルシューティング)
11. [本番環境のベストプラクティス](#本番環境のベストプラクティス)

---

## 前提条件

### 必要なアカウント

- **Heroku アカウント**: https://signup.heroku.com/
- **AWS アカウント**: S3（ファイルストレージ）と Rekognition（コンテンツモデレーション）用

### 必要なツール

```bash
# Heroku CLI のインストール（macOS）
brew tap heroku/brew && brew install heroku

# または公式インストーラー
# https://devcenter.heroku.com/articles/heroku-cli

# インストール確認
heroku --version
# heroku/8.x.x ...

# Heroku にログイン
heroku login
```

---

## 事前準備

### 1. Git リポジトリの確認

```bash
cd local-photo-contest
git status
# 全ての変更がコミットされていることを確認
```

### 2. Procfile の作成

プロジェクトルートに `Procfile` を作成します：

```bash
# Procfile（拡張子なし）
cat > Procfile << 'EOF'
web: bundle exec puma -C config/puma.rb
worker: bundle exec rake solid_queue:start
release: bundle exec rails db:migrate
EOF
```

### 3. 本番用ストレージ設定

`config/storage.yml` に Amazon S3 の設定を追加：

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: <%= ENV.fetch('AWS_REGION', 'ap-northeast-1') %>
  bucket: <%= ENV['S3_BUCKET_NAME'] %>
```

### 4. 本番環境のストレージ設定を更新

`config/environments/production.rb` を編集：

```ruby
# 変更前
config.active_storage.service = :local

# 変更後
config.active_storage.service = :amazon
```

### 5. 変更をコミット

```bash
git add .
git commit -m "Add Heroku deployment configuration"
```

---

## Heroku アプリの作成

### 1. アプリを作成

```bash
# アプリ名を指定して作成（グローバルでユニークな名前が必要）
heroku create local-photo-contest-app

# または自動生成の名前で作成
heroku create

# 作成されたアプリのURLを確認
# https://local-photo-contest-app.herokuapp.com/
```

### 2. ビルドパックの確認

```bash
heroku buildpacks
# heroku/ruby が設定されていることを確認
```

### 3. スタックの確認

```bash
heroku stack
# heroku-24 または最新のスタックを使用
```

---

## アドオンの設定

### 1. PostgreSQL データベース

```bash
# Essential プラン（$5/月）を追加
heroku addons:create heroku-postgresql:essential-0

# または無料の Mini プラン（開発/テスト用、制限あり）
# heroku addons:create heroku-postgresql:mini

# データベース情報を確認
heroku pg:info
```

### 2. Redis（オプション：Action Cable 用）

Solid Cable を使用する場合は Redis は不要ですが、パフォーマンスを重視する場合：

```bash
# Redis を追加（必要な場合のみ）
heroku addons:create heroku-redis:mini
```

### 3. メール送信（SendGrid）

```bash
# SendGrid を追加
heroku addons:create sendgrid:starter

# APIキーを確認
heroku config:get SENDGRID_API_KEY
```

---

## 環境変数の設定

### 1. 必須の環境変数

```bash
# Rails マスターキー（credentials.yml.enc の復号に必要）
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

# Rails 環境
heroku config:set RAILS_ENV=production

# ログレベル
heroku config:set RAILS_LOG_LEVEL=info

# Solid Queue を Puma 内で実行（小規模デプロイ用）
# Dyno を節約したい場合に設定
# heroku config:set SOLID_QUEUE_IN_PUMA=true
```

### 2. AWS 設定

```bash
# AWS 認証情報
heroku config:set AWS_ACCESS_KEY_ID=your_access_key_id
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret_access_key
heroku config:set AWS_REGION=ap-northeast-1

# S3 バケット名
heroku config:set S3_BUCKET_NAME=your-bucket-name
```

### 3. コンテンツモデレーション設定

```bash
# モデレーション機能の有効化
heroku config:set MODERATION_ENABLED=true
heroku config:set MODERATION_PROVIDER=rekognition
heroku config:set MODERATION_THRESHOLD=60.0
```

### 4. アプリケーション設定

```bash
# ホスト名（メールのリンク生成等に使用）
heroku config:set APP_HOST=your-app-name.herokuapp.com

# タイムゾーン（オプション）
heroku config:set TZ=Asia/Tokyo
```

### 5. 設定の確認

```bash
heroku config
```

---

## AWS S3 の設定

### 1. S3 バケットの作成

AWS コンソールまたは CLI で S3 バケットを作成します：

```bash
# AWS CLI を使用する場合
aws s3 mb s3://your-bucket-name --region ap-northeast-1
```

### 2. バケットポリシーの設定

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        }
    ]
}
```

### 3. CORS 設定

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
        "AllowedOrigins": ["https://your-app-name.herokuapp.com"],
        "ExposeHeaders": []
    }
]
```

### 4. IAM ユーザーのポリシー

S3 と Rekognition の両方にアクセスできる IAM ポリシー：

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "rekognition:DetectModerationLabels"
            ],
            "Resource": "*"
        }
    ]
}
```

---

## デプロイ

### 1. 初回デプロイ

```bash
# Heroku にプッシュ
git push heroku main

# デプロイログを確認
heroku logs --tail
```

### 2. データベースのセットアップ

```bash
# マイグレーションは release フェーズで自動実行されます
# 手動で実行する場合：
heroku run rails db:migrate

# 初期データの投入（必要な場合）
heroku run rails db:seed
```

### 3. Dyno の確認と起動

```bash
# Dyno の状態を確認
heroku ps

# Web Dyno を起動
heroku ps:scale web=1

# Worker Dyno を起動（Solid Queue 用）
heroku ps:scale worker=1
```

### 4. アプリケーションを開く

```bash
heroku open
```

---

## デプロイ後の設定

### 1. カスタムドメインの設定（オプション）

```bash
# ドメインを追加
heroku domains:add www.your-domain.com

# DNS 設定を確認
heroku domains
```

### 2. SSL 証明書

Heroku の有料プランでは自動的に SSL が有効になります。

### 3. 管理者ユーザーの作成

```bash
heroku run rails console
```

```ruby
# Rails コンソール内で実行
User.create!(
  email: 'admin@example.com',
  password: 'secure_password',
  password_confirmation: 'secure_password',
  role: :admin,
  confirmed_at: Time.current
)
```

---

## 運用コマンド

### ログの確認

```bash
# リアルタイムログ
heroku logs --tail

# 特定の Dyno のログ
heroku logs --tail --dyno web

# 直近のログ（行数指定）
heroku logs -n 500
```

### Rails コンソール

```bash
heroku run rails console
```

### データベース操作

```bash
# psql でデータベースに接続
heroku pg:psql

# データベースのバックアップ
heroku pg:backups:capture

# バックアップの一覧
heroku pg:backups

# バックアップのダウンロード
heroku pg:backups:download
```

### メンテナンスモード

```bash
# メンテナンスモードを有効化
heroku maintenance:on

# メンテナンスモードを無効化
heroku maintenance:off
```

### Dyno の再起動

```bash
# 全ての Dyno を再起動
heroku restart

# 特定の Dyno を再起動
heroku restart web.1
```

---

## トラブルシューティング

### デプロイが失敗する

```bash
# ビルドログを確認
heroku builds:info

# 詳細なログを確認
heroku logs --tail
```

### データベース接続エラー

```bash
# DATABASE_URL を確認
heroku config:get DATABASE_URL

# データベースの状態を確認
heroku pg:info
```

### Asset Pipeline のエラー

```bash
# アセットを手動でプリコンパイル
heroku run rails assets:precompile
```

### Solid Queue が動かない

```bash
# Worker Dyno が起動しているか確認
heroku ps

# Worker を起動
heroku ps:scale worker=1

# Worker のログを確認
heroku logs --tail --dyno worker
```

### メモリ不足

```bash
# メモリ使用量を確認
heroku logs --tail | grep Memory

# Dyno タイプをアップグレード
heroku ps:type web=standard-1x
```

### Active Storage のアップロードエラー

1. S3 バケットの CORS 設定を確認
2. IAM ポリシーを確認
3. 環境変数を確認

```bash
heroku config:get AWS_ACCESS_KEY_ID
heroku config:get S3_BUCKET_NAME
```

---

## 本番環境のベストプラクティス

### 1. Dyno タイプの選択

| 用途 | 推奨 Dyno タイプ |
|------|-----------------|
| 開発/テスト | Basic ($7/月) |
| 小規模運用 | Standard-1X ($25/月) |
| 中規模運用 | Standard-2X ($50/月) |
| 大規模運用 | Performance ($250/月〜) |

### 2. データベースプランの選択

| 用途 | 推奨プラン |
|------|-----------|
| 開発/テスト | Essential-0 ($5/月) |
| 小規模運用 | Essential-1 ($15/月) |
| 中規模運用 | Standard-0 ($50/月) |
| 大規模運用 | Premium ($200/月〜) |

### 3. スケーリング戦略

```bash
# 水平スケーリング（Web Dyno を増やす）
heroku ps:scale web=2

# 垂直スケーリング（Dyno タイプを上げる）
heroku ps:type web=standard-2x

# 自動スケーリング（有料アドオン）
# Heroku Autoscaling または HireFire.io を検討
```

### 4. 監視の設定

```bash
# New Relic APM（推奨）
heroku addons:create newrelic:wayne

# Papertrail（ログ管理）
heroku addons:create papertrail:choklad

# Sentry（エラートラッキング）
heroku addons:create sentry:f1
```

### 5. セキュリティ

- `RAILS_MASTER_KEY` を安全に管理
- AWS 認証情報は IAM ロールで最小権限を付与
- 定期的なセキュリティアップデート
- `heroku config` の値を定期的に監査

### 6. バックアップ戦略

```bash
# 自動バックアップを有効化（Standard プラン以上）
heroku pg:backups:schedule DATABASE_URL --at '04:00 Asia/Tokyo'

# バックアップのスケジュールを確認
heroku pg:backups:schedules
```

---

## 月額コスト見積もり（参考）

### 最小構成

| 項目 | プラン | 月額 |
|------|--------|------|
| Web Dyno | Basic | $7 |
| Worker Dyno | Basic | $7 |
| PostgreSQL | Essential-0 | $5 |
| **合計** | | **$19** |

### 推奨構成（小規模運用）

| 項目 | プラン | 月額 |
|------|--------|------|
| Web Dyno | Standard-1X | $25 |
| Worker Dyno | Standard-1X | $25 |
| PostgreSQL | Essential-1 | $15 |
| SendGrid | Starter | $0 |
| **合計** | | **$65** |

### 本番構成（中規模運用）

| 項目 | プラン | 月額 |
|------|--------|------|
| Web Dyno x2 | Standard-1X | $50 |
| Worker Dyno | Standard-1X | $25 |
| PostgreSQL | Standard-0 | $50 |
| Redis | Mini | $3 |
| SendGrid | Essentials | $20 |
| New Relic | Wayne | $0 |
| **合計** | | **$148** |

> 注: AWS S3 と Rekognition の料金は別途発生します。

---

## 参考リンク

- [Heroku Dev Center](https://devcenter.heroku.com/)
- [Getting Started with Rails 8 on Heroku](https://devcenter.heroku.com/articles/getting-started-with-rails8)
- [Heroku PostgreSQL](https://devcenter.heroku.com/articles/heroku-postgresql)
- [Active Storage with S3](https://edgeguides.rubyonrails.org/active_storage_overview.html#amazon-s3-service)
- [Solid Queue](https://github.com/rails/solid_queue)

---

*このドキュメントは Local Photo Contest v1.0 に基づいています。*
