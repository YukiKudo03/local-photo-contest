# Docker 開発環境セットアップガイド

このガイドでは、Docker Compose を使用した開発環境の構築方法を説明します。

---

## 目次

1. [前提条件](#前提条件)
2. [クイックスタート](#クイックスタート)
3. [サービス構成](#サービス構成)
4. [環境変数の設定](#環境変数の設定)
5. [よく使うコマンド](#よく使うコマンド)
6. [開発ワークフロー](#開発ワークフロー)
7. [トラブルシューティング](#トラブルシューティング)

---

## 前提条件

以下がインストールされていることを確認してください：

- **Docker** (20.10 以上)
- **Docker Compose** (2.0 以上)

### インストール確認

```bash
docker --version
# Docker version 24.0.0, build ...

docker compose version
# Docker Compose version v2.20.0
```

---

## クイックスタート

### 1. リポジトリをクローン

```bash
git clone https://github.com/your-org/local-photo-contest.git
cd local-photo-contest
```

### 2. 環境変数ファイルを作成

```bash
cp .env.docker.example .env
```

必要に応じて `.env` ファイルを編集してください（特にAWS認証情報）。

### 3. コンテナをビルド・起動

```bash
docker compose up --build
```

初回起動時は以下が自動的に実行されます：
- Docker イメージのビルド
- Gem のインストール
- データベースの作成とマイグレーション

### 4. アプリケーションにアクセス

ブラウザで以下にアクセス：

```
http://localhost:3000
```

---

## サービス構成

Docker Compose で以下のサービスが起動します：

| サービス | コンテナ名 | ポート | 説明 |
|----------|-----------|--------|------|
| `db` | lpc_db | 5432 | PostgreSQL データベース |
| `redis` | lpc_redis | 6379 | Redis (キャッシュ・Action Cable) |
| `web` | lpc_web | 3000 | Rails アプリケーション |
| `worker` | lpc_worker | - | Solid Queue ワーカー (バックグラウンドジョブ) |
| `css` | lpc_css | - | Tailwind CSS ウォッチャー |

### アーキテクチャ図

```
                    ┌─────────────────┐
                    │   Browser       │
                    │ localhost:3000  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │      web        │
                    │  Rails Server   │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼───────┐   ┌───────▼───────┐   ┌───────▼───────┐
│      db       │   │     redis     │   │    worker     │
│  PostgreSQL   │   │    Redis      │   │  Solid Queue  │
└───────────────┘   └───────────────┘   └───────────────┘
```

---

## 環境変数の設定

### データベース設定

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `DB_USER` | postgres | PostgreSQL ユーザー名 |
| `DB_PASSWORD` | password | PostgreSQL パスワード |
| `DB_NAME` | local_photo_contest_development | データベース名 |
| `DB_PORT` | 5432 | PostgreSQL ポート |

### AWS設定（コンテンツモデレーション用）

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `AWS_REGION` | ap-northeast-1 | AWS リージョン |
| `AWS_ACCESS_KEY_ID` | - | AWS アクセスキー ID |
| `AWS_SECRET_ACCESS_KEY` | - | AWS シークレットアクセスキー |

### モデレーション設定

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `MODERATION_ENABLED` | true | モデレーション機能の有効/無効 |
| `MODERATION_PROVIDER` | rekognition | 使用するプロバイダー |
| `MODERATION_THRESHOLD` | 60.0 | 検出閾値 (0-100) |

---

## よく使うコマンド

### 基本操作

```bash
# すべてのサービスを起動
docker compose up

# バックグラウンドで起動
docker compose up -d

# すべてのサービスを停止
docker compose down

# ボリュームも含めて削除（データベースリセット）
docker compose down -v

# 特定のサービスのログを表示
docker compose logs -f web
docker compose logs -f worker

# すべてのログを表示
docker compose logs -f
```

### Rails コマンド

```bash
# Rails コンソール
docker compose exec web rails c

# マイグレーション実行
docker compose exec web rails db:migrate

# データベースリセット
docker compose exec web rails db:reset

# シードデータ投入
docker compose exec web rails db:seed

# ルート一覧
docker compose exec web rails routes

# Rake タスク一覧
docker compose exec web rails -T
```

### テスト

```bash
# RSpec 実行
docker compose exec web bundle exec rspec

# 特定のファイルをテスト
docker compose exec web bundle exec rspec spec/models/entry_spec.rb
```

### Gem 管理

```bash
# Gem をインストール（Gemfile更新後）
docker compose exec web bundle install

# イメージを再ビルド（大きな変更後）
docker compose build --no-cache web
```

### コンテナ内シェル

```bash
# web コンテナにシェルで入る
docker compose exec web bash

# db コンテナで psql を実行
docker compose exec db psql -U postgres -d local_photo_contest_development
```

---

## 開発ワークフロー

### 1. 起動

```bash
# ターミナル1: サービス起動（ログ表示）
docker compose up
```

### 2. コード編集

ホストマシンでコードを編集します。ファイルの変更は自動的にコンテナに反映されます。

### 3. データベース変更

```bash
# マイグレーション作成
docker compose exec web rails g migration AddColumnToTable

# マイグレーション実行
docker compose exec web rails db:migrate
```

### 4. テスト実行

```bash
docker compose exec web bundle exec rspec
```

### 5. 終了

```bash
# Ctrl+C でログ表示を終了後
docker compose down
```

---

## トラブルシューティング

### ポートが使用中

```
Error: bind: address already in use
```

**解決方法:**

```bash
# 使用中のプロセスを確認
lsof -i :3000
lsof -i :5432

# または .env でポートを変更
WEB_PORT=3001
DB_PORT=5433
```

### データベース接続エラー

```
PG::ConnectionBad: could not connect to server
```

**解決方法:**

```bash
# データベースコンテナの状態を確認
docker compose ps

# データベースを再起動
docker compose restart db

# ログを確認
docker compose logs db
```

### Gem のインストールエラー

```
Could not find gem 'xxx'
```

**解決方法:**

```bash
# bundle install を実行
docker compose exec web bundle install

# それでもダメなら再ビルド
docker compose build --no-cache web
```

### ボリュームのパーミッションエラー

```
Permission denied
```

**解決方法:**

```bash
# ボリュームを削除して再作成
docker compose down -v
docker compose up --build
```

### Tailwind CSS が反映されない

**解決方法:**

```bash
# CSS コンテナのログを確認
docker compose logs css

# CSS コンテナを再起動
docker compose restart css
```

### バックグラウンドジョブが動かない

**解決方法:**

```bash
# worker コンテナのログを確認
docker compose logs worker

# worker を再起動
docker compose restart worker
```

---

## ローカル開発（Docker なし）との切り替え

### Docker を使う場合

```bash
docker compose up
# http://localhost:3000
```

### ローカルで直接実行する場合

```bash
# PostgreSQL ではなく SQLite を使用
unset DB_HOST

# 通常の Rails コマンド
bundle install
rails db:prepare
rails server
```

> 💡 `DB_HOST` 環境変数が設定されていない場合、自動的に SQLite が使用されます。

---

## 参考リンク

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Rails on Docker](https://guides.rubyonrails.org/getting_started_with_devcontainer.html)

---

*このドキュメントは Local Photo Contest v1.0 に基づいています。*
