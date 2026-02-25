# システム管理者向け利用マニュアル

このマニュアルでは、Local Photo Contest システムの管理・運用方法をご案内します。

---

## 目次

1. [システム概要](#1-システム概要)
2. [管理画面へのアクセス](#2-管理画面へのアクセス)
3. [ユーザー管理](#3-ユーザー管理)
4. [コンテスト管理](#4-コンテスト管理)
5. [カテゴリ管理](#5-カテゴリ管理)
6. [監査ログ](#6-監査ログ)
7. [チュートリアル分析](#7-チュートリアル分析)
8. [コンテンツモデレーション設定](#8-コンテンツモデレーション設定)
9. [システム監視](#9-システム監視)
10. [バックアップと復元](#10-バックアップと復元)
11. [チュートリアル・ヘルプ](#11-チュートリアルヘルプ)
12. [トラブルシューティング](#12-トラブルシューティング)

---

## 1. システム概要

### システム構成

```
┌─────────────────────────────────────────────────────────┐
│                    Web Application                       │
│                  (Ruby on Rails 8.0)                     │
├─────────────────────────────────────────────────────────┤
│  Frontend: Hotwire (Turbo + Stimulus) + Tailwind CSS    │
├─────────────────────────────────────────────────────────┤
│  Database: PostgreSQL                                    │
│  Storage: Active Storage (ローカル or S3)               │
│  Job Queue: Solid Queue / Sidekiq                       │
│  外部連携: AWS Rekognition (コンテンツ審査)             │
└─────────────────────────────────────────────────────────┘
```

### ユーザーロール

| ロール | 説明 | 権限 |
|--------|------|------|
| 一般ユーザー | コンテスト参加者 | 応募、投票、コメント |
| 主催者 (Organizer) | コンテスト運営者 | コンテスト作成・管理、モデレーション |
| 管理者 (Admin) | システム管理者 | 全機能、ユーザー管理、システム設定 |

---

## 2. 管理画面へのアクセス

### アクセス方法

1. 管理者権限を持つアカウントでログイン
2. 画面右上の「**管理画面**」リンクをクリック
3. 管理画面ダッシュボードが表示されます

### 管理画面のナビゲーション

| メニュー | 説明 |
|----------|------|
| ダッシュボード | 管理画面のトップページ |
| ユーザー | ユーザー管理 |
| コンテスト | コンテスト一覧・管理 |
| カテゴリ | カテゴリ管理 |
| 監査ログ | システムの操作履歴 |
| チュートリアル分析 | チュートリアルの利用状況 |

---

## 3. ユーザー管理

### ユーザー一覧

管理画面 → 「**ユーザー**」から、すべてのユーザーを確認できます。

#### 表示される情報

- メールアドレス
- ロール（一般/主催者/管理者）
- 登録日
- 最終ログイン日時
- アカウント状態（有効/ロック中）

### ユーザーの検索・絞り込み

- **キーワード検索**: メールアドレスで検索
- **ロール絞り込み**: 一般/主催者/管理者でフィルタ

### ロールの変更

1. ユーザー一覧から対象ユーザーを選択
2. 「**編集**」をクリック
3. ロールを変更して「**更新**」

#### ロール変更時の注意

| 変更 | 影響 |
|------|------|
| 一般 → 主催者 | ダッシュボードにアクセス可能になる |
| 主催者 → 管理者 | 管理画面にアクセス可能になる |
| 主催者 → 一般 | 作成済みコンテストは維持される |

### アカウントのロック・解除

#### アカウントをロック

問題のあるユーザーのアカウントを一時停止できます：

1. ユーザー詳細ページを開く
2. 「**アカウントをロック**」をクリック
3. ロックされたユーザーはログインできなくなります

#### アカウントのロック解除

1. ユーザー詳細ページを開く
2. 「**ロックを解除**」をクリック

> 💡 ログイン失敗が一定回数を超えると、自動的にアカウントがロックされます。

### ユーザーの削除

1. ユーザー詳細ページを開く
2. 「**削除**」をクリック
3. 確認ダイアログで「**OK**」

> ⚠️ **注意**: ユーザーを削除すると、そのユーザーの応募、コメント、投票も削除されます。

---

## 4. コンテスト管理

### コンテスト一覧

管理画面 → 「**コンテスト**」から、すべてのコンテストを確認できます。

### コンテストの強制終了

問題のあるコンテストを強制終了できます：

1. コンテスト詳細ページを開く
2. 「**強制終了**」をクリック

### コンテストの削除

1. コンテスト詳細ページを開く
2. 「**削除**」をクリック

> ⚠️ 削除すると、関連するすべての応募、投票、評価も削除されます。

---

## 5. カテゴリ管理

### カテゴリ一覧

管理画面 → 「**カテゴリ**」から、カテゴリを管理できます。

### カテゴリの作成

1. 「**新規カテゴリ作成**」をクリック
2. 以下の情報を入力：
   - カテゴリ名
   - 説明（任意）
   - 表示順
3. 「**作成**」をクリック

### カテゴリの編集・削除

- 各カテゴリの「**編集**」「**削除**」ボタンから操作

> ⚠️ 使用中のカテゴリは削除できません。

---

## 6. 監査ログ

### 監査ログとは

システム内で行われた重要な操作を記録したログです。

### 確認できる操作

| 操作タイプ | 内容 |
|------------|------|
| ユーザー関連 | ログイン/ログアウト、ロール変更、アカウントロック/解除 |
| コンテスト関連 | 作成、公開、終了、削除 |
| モデレーション | 承認、却下 |
| カテゴリ関連 | 作成、編集、削除 |

### ログの検索・絞り込み

- **期間**: 日付範囲で絞り込み
- **操作タイプ**: 特定の操作で絞り込み
- **ユーザー**: 特定のユーザーの操作のみ表示

### ログの詳細表示

各ログをクリックすると、以下の詳細情報を確認できます：

- 操作日時
- 操作者（メールアドレス）
- 操作内容
- 対象リソース
- IPアドレス
- 追加情報（変更前後の値など）

---

## 7. チュートリアル分析

### チュートリアル分析とは

ユーザーのチュートリアル利用状況を確認できる機能です。

### アクセス方法

管理画面 → 「**チュートリアル分析**」

### 確認できる情報

#### 概要

- チュートリアル完了率
- スキップ率
- 平均所要時間

#### チュートリアル別統計

| チュートリアル | 完了数 | スキップ数 | 完了率 |
|---------------|--------|----------|--------|
| 参加者オンボーディング | 150 | 20 | 88% |
| 主催者オンボーディング | 30 | 5 | 86% |
| 審査員オンボーディング | 10 | 2 | 83% |

#### ロール別分析

- 参加者のチュートリアル利用状況
- 主催者のチュートリアル利用状況
- 管理者のチュートリアル利用状況

### 活用方法

- 完了率が低いチュートリアルの改善
- スキップが多いステップの見直し
- ユーザー体験の向上

---

## 8. コンテンツモデレーション設定

### グローバル設定

システム全体のモデレーション設定は環境変数で管理します。

#### 環境変数

```bash
# .env ファイル

# モデレーション機能の有効/無効（デフォルト: true）
MODERATION_ENABLED=true

# 使用するプロバイダー（デフォルト: rekognition）
MODERATION_PROVIDER=rekognition

# デフォルト閾値（デフォルト: 60.0）
MODERATION_THRESHOLD=60.0

# AWS設定（Rekognition用）
AWS_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
```

### AWS Rekognition の設定

#### IAMポリシー

Rekognition を使用するには、以下の権限が必要です：

```json
{
  "Version": "2012-10-17",
  "Statement": [
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

#### 料金

AWS Rekognition の画像処理料金：
- 最初の100万枚/月: $1.00 / 1,000枚
- 以降: $0.80 / 1,000枚

> 💡 詳細は [AWS Rekognition 料金](https://aws.amazon.com/rekognition/pricing/) を参照

### モデレーションジョブの監視

ジョブキューの状態を確認：

```ruby
# Rails コンソール

# 保留中のジョブ数
ModerationJob.queue_adapter.enqueued_jobs.count

# Sidekiq使用時
require 'sidekiq/api'
Sidekiq::Queue.new('moderation').size
```

---

## 9. システム監視

### ログの確認

```bash
# アプリケーションログ
tail -f log/production.log

# ジョブログ（Sidekiq使用時）
tail -f log/sidekiq.log
```

### 重要なメトリクス

監視すべき項目：

| メトリクス | 確認方法 | 警告閾値 |
|-----------|----------|----------|
| ジョブキュー長 | Sidekiq Dashboard | > 100 |
| 要確認応募数 | 管理画面 | > 10/日 |
| エラーログ | log/production.log | 増加傾向 |
| ディスク使用量 | df -h | > 80% |

### ジョブの再実行

失敗したジョブを再実行：

```ruby
# Sidekiq使用時
require 'sidekiq/api'
rs = Sidekiq::RetrySet.new
rs.each(&:retry)

# 特定のジョブを再実行
Sidekiq::RetrySet.new.select { |job| job.klass == 'ModerationJob' }.each(&:retry)
```

---

## 10. バックアップと復元

### データベースバックアップ

```bash
# PostgreSQL
pg_dump -h localhost -U username dbname > backup_$(date +%Y%m%d).sql

# 圧縮バックアップ
pg_dump -h localhost -U username dbname | gzip > backup_$(date +%Y%m%d).sql.gz
```

### 画像ファイルのバックアップ

```bash
# Active Storage (ローカル)
tar -czf storage_backup_$(date +%Y%m%d).tar.gz storage/

# S3使用時は AWS CLI を使用
aws s3 sync s3://your-bucket ./backup/
```

### 復元

```bash
# データベース
psql -h localhost -U username dbname < backup.sql

# 画像ファイル
tar -xzf storage_backup.tar.gz -C /path/to/app/
```

---

## 11. チュートリアル・ヘルプ

### 初回アクセス時のチュートリアル

管理画面に初めてアクセスすると、管理機能の概要を説明するチュートリアルが表示されます：

- 管理画面のナビゲーション
- ユーザー管理の基本操作
- 監査ログの確認方法

### チュートリアル設定

チュートリアルの表示設定はプロフィールページから変更できます。

### ヘルプページへのアクセス

1. 管理画面ヘッダーの「**管理者ガイド**」をクリック
2. またはサイト全体の「**ヘルプ**」から「管理者向けマニュアル」を選択

> 💡 このマニュアルは「管理者向けマニュアル」です。

---

## 12. トラブルシューティング

### モデレーションが動作しない

**症状**: 応募しても審査が実行されない

**確認項目**:

1. 環境変数の確認
```bash
echo $MODERATION_ENABLED
echo $MODERATION_PROVIDER
```

2. AWS認証情報の確認
```ruby
# Rails コンソール
Aws::Rekognition::Client.new.detect_moderation_labels(
  image: { bytes: File.read('test.jpg') }
)
```

3. ジョブキューの状態確認
```ruby
# Sidekiq Dashboard または
Sidekiq::Queue.new('moderation').size
```

4. コンテストの設定確認
```ruby
contest = Contest.find(123)
contest.moderation_enabled?
```

### AWS Rekognition エラー

**エラー**: `Aws::Rekognition::Errors::InvalidImageFormatException`

**原因**: 対応していない画像形式

**対処**:
- 対応形式: JPEG, PNG
- 画像サイズ制限: 5MB（S3経由の場合は15MB）

---

**エラー**: `Aws::Rekognition::Errors::UnrecognizedClientException`

**原因**: AWS認証情報が無効

**対処**:
```bash
# 認証情報を確認
aws sts get-caller-identity

# 環境変数を再設定
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
```

---

**エラー**: `Aws::Rekognition::Errors::ThrottlingException`

**原因**: APIレート制限

**対処**:
- リトライロジックは自動で実行されます
- 頻発する場合は AWS にリミット増加をリクエスト

### ジョブが詰まっている

**症状**: モデレーションキューが増え続ける

**対処**:

1. ワーカー数の確認
```bash
# Sidekiq
ps aux | grep sidekiq
```

2. ワーカーの追加
```yaml
# config/sidekiq.yml
:concurrency: 10
:queues:
  - [moderation, 5]
  - [default, 1]
```

3. キューのクリア（注意して実行）
```ruby
Sidekiq::Queue.new('moderation').clear
```

### ディスク容量不足

**症状**: 画像アップロードが失敗する

**対処**:

1. 不要なファイルを削除
```bash
# 古いログを削除
find log/ -name "*.log" -mtime +30 -delete

# tmp ファイルを削除
rails tmp:clear
```

2. 未使用の Active Storage blob を削除
```ruby
# Rails コンソール
ActiveStorage::Blob.unattached.where('created_at < ?', 1.week.ago).find_each(&:purge)
```

---

## 付録: 便利なコマンド集

### Rails コンソール

```ruby
# 統計情報
puts "ユーザー数: #{User.count}"
puts "コンテスト数: #{Contest.count}"
puts "応募数: #{Entry.count}"
puts "要確認応募: #{Entry.moderation_requires_review.count}"

# 最近の応募
Entry.order(created_at: :desc).limit(10)

# モデレーション統計
Entry.group(:moderation_status).count
```

### シェルコマンド

```bash
# アプリケーションの再起動
bundle exec rails restart

# キャッシュクリア
bundle exec rails cache:clear

# アセット再コンパイル
bundle exec rails assets:precompile

# データベースマイグレーション
bundle exec rails db:migrate
```

---

## 緊急連絡先

重大な障害が発生した場合は、以下に連絡してください：

- **開発チーム**: dev-team@example.com
- **インフラチーム**: infra@example.com

---

*このマニュアルは Local Photo Contest v1.2 に基づいています。*
