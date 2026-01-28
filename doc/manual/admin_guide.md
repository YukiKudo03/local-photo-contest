# システム管理者向け利用マニュアル

このマニュアルでは、Local Photo Contest システムの管理・運用方法をご案内します。

---

## 目次

1. [システム概要](#1-システム概要)
2. [ユーザー管理](#2-ユーザー管理)
3. [カテゴリ管理](#3-カテゴリ管理)
4. [コンテンツモデレーション設定](#4-コンテンツモデレーション設定)
5. [システム監視](#5-システム監視)
6. [バックアップと復元](#6-バックアップと復元)
7. [トラブルシューティング](#7-トラブルシューティング)

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

## 2. ユーザー管理

### ユーザー一覧の確認

Rails コンソールまたは管理画面からユーザー情報を確認できます。

```ruby
# Rails コンソール
rails console

# 全ユーザー一覧
User.all

# 主催者一覧
User.where(role: :organizer)

# 特定ユーザーの検索
User.find_by(email: 'user@example.com')
```

### 主催者権限の付与

```ruby
# Rails コンソール
user = User.find_by(email: 'user@example.com')
user.update!(role: :organizer)
```

### 主催者権限の剥奪

```ruby
# Rails コンソール
user = User.find_by(email: 'organizer@example.com')
user.update!(role: :user)
```

> ⚠️ **注意**: 権限を剥奪しても、作成済みのコンテストは削除されません。

### ユーザーの無効化

問題のあるユーザーを無効化する場合：

```ruby
# Rails コンソール
user = User.find_by(email: 'problem_user@example.com')
# Deviseの場合
user.update!(locked_at: Time.current)
```

---

## 3. カテゴリ管理

コンテストのカテゴリを管理します。

### カテゴリの作成

```ruby
# Rails コンソール
Category.create!(
  name: '風景写真',
  description: '自然や都市の風景',
  position: 1
)
```

### カテゴリの編集

```ruby
category = Category.find_by(name: '風景写真')
category.update!(name: 'ランドスケープ')
```

### カテゴリの並び順変更

```ruby
category = Category.find_by(name: '風景写真')
category.update!(position: 3)
```

---

## 4. コンテンツモデレーション設定

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

### モデレーション結果の確認

```ruby
# Rails コンソール

# 要確認の応募一覧
Entry.moderation_requires_review

# 非表示の応募一覧
Entry.moderation_hidden

# 特定の応募のモデレーション結果
entry = Entry.find(123)
entry.moderation_result
entry.moderation_result.labels  # 検出されたラベル
entry.moderation_result.max_confidence  # 最大信頼度
```

### 手動でモデレーションを実行

```ruby
# Rails コンソール

# 特定の応募を再審査
entry = Entry.find(123)
Moderation::ModerationService.moderate(entry)

# 全ての未審査応募を処理
Entry.moderation_pending.find_each do |entry|
  ModerationJob.perform_later(entry.id)
end
```

---

## 5. システム監視

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

## 6. バックアップと復元

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

## 7. トラブルシューティング

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

*このマニュアルは Local Photo Contest v1.0 に基づいています。*
