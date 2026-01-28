# Content Moderation 開発者ガイド

## 概要

コンテンツモデレーション機能は、フォトコンテストに投稿された画像を自動審査し、不適切なコンテンツを検出・管理するシステムです。

### 主な機能

- **自動画像審査**: AWS Rekognition DetectModerationLabels APIによる画像分析
- **非同期処理**: 投稿時のUXを損なわない非同期審査
- **プロバイダー抽象化**: 複数の審査プロバイダーに対応可能な設計
- **主催者向け管理UI**: 検出されたコンテンツの確認・承認・却下
- **コンテスト単位の設定**: 有効/無効、閾値のカスタマイズ

## アーキテクチャ

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│     Entry       │────▶│  ModerationJob   │────▶│  ModerationService  │
│  (after_create) │     │   (async queue)  │     │   (orchestration)   │
└─────────────────┘     └──────────────────┘     └──────────┬──────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│ModerationResult │◀────│    Providers     │◀────│  RekognitionProvider│
│   (storage)     │     │   (registry)     │     │    (AWS SDK)        │
└─────────────────┘     └──────────────────┘     └─────────────────────┘
```

## データモデル

### ModerationResult

モデレーション結果を保存するモデル。

```ruby
# カラム
- entry_id: integer (FK)
- provider: string          # "rekognition" など
- status: integer (enum)    # pending, approved, rejected, requires_review
- labels: jsonb             # 検出されたラベルの配列
- max_confidence: decimal   # 最大信頼度
- raw_response: jsonb       # プロバイダーからの生レスポンス
- reviewed_by_id: integer   # レビュアーのユーザーID
- reviewed_at: datetime
- review_note: text
```

### Entry の追加カラム

```ruby
- moderation_status: integer (enum)
  # moderation_pending: 0    - 審査待ち
  # moderation_approved: 1   - 承認済み
  # moderation_hidden: 2     - 非表示
  # moderation_requires_review: 3 - 要確認
```

### Contest の追加カラム

```ruby
- moderation_enabled: boolean (default: true)
- moderation_threshold: decimal (default: 60.0)
```

## サービス層

### Moderation::ModerationService

モデレーション処理のオーケストレーションを行うメインサービス。

```ruby
# 使用例
result = Moderation::ModerationService.moderate(entry)

# 戻り値
{
  status: :approved | :hidden | :requires_review | :skipped | :error,
  labels: [...],
  max_confidence: 85.5,
  message: "..."
}
```

### Moderation::Providers

プロバイダーのレジストリモジュール。

```ruby
# 現在のプロバイダーを取得
provider = Moderation::Providers.current

# 利用可能なプロバイダー一覧
Moderation::Providers.available  # => [:rekognition]

# 特定のプロバイダーを取得
Moderation::Providers.get(:rekognition)
```

### Moderation::Providers::RekognitionProvider

AWS Rekognition実装。

```ruby
provider = Moderation::Providers::RekognitionProvider.new
result = provider.analyze(entry.photo)

# result.labels => [{ "Name" => "Explicit", "Confidence" => 95.5 }, ...]
# result.max_confidence => 95.5
# result.violation_detected? => true/false
```

## 設定

### 環境変数

```bash
# config/initializers/moderation.rb で使用

# プロバイダー選択
MODERATION_PROVIDER=rekognition

# グローバルデフォルト閾値
MODERATION_THRESHOLD=60.0

# 機能の有効/無効
MODERATION_ENABLED=true

# AWS設定（Rekognition用）
AWS_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
```

### Rails設定

```ruby
# config/initializers/moderation.rb

Rails.application.config.moderation = ActiveSupport::OrderedOptions.new
Rails.application.config.moderation.provider = ENV.fetch("MODERATION_PROVIDER", "rekognition")
Rails.application.config.moderation.threshold = ENV.fetch("MODERATION_THRESHOLD", 60.0).to_f
Rails.application.config.moderation.enabled = ENV.fetch("MODERATION_ENABLED", "true") == "true"
```

## ジョブキュー

ModerationJobは `moderation` キューで実行されます。

```ruby
# config/sidekiq.yml など
:queues:
  - default
  - moderation
  - mailers
```

### リトライ設定

```ruby
class ModerationJob < ApplicationJob
  queue_as :moderation

  # API エラー時は指数バックオフでリトライ
  retry_on Moderation::Providers::RekognitionProvider::AnalysisError,
           wait: :polynomially_longer,
           attempts: 3

  # レコードが見つからない場合は破棄
  discard_on ActiveJob::DeserializationError
end
```

## 新しいプロバイダーの追加

### 1. プロバイダークラスを作成

```ruby
# app/services/moderation/providers/my_provider.rb

module Moderation
  module Providers
    class MyProvider < BaseProvider
      def name
        :my_provider
      end

      def analyze(attachment)
        # 画像分析ロジックを実装
        # ...

        Result.new(
          labels: detected_labels,
          max_confidence: max_confidence,
          raw_response: api_response
        )
      end
    end

    # プロバイダーを登録
    Providers.register(:my_provider, MyProvider)
  end
end
```

### 2. 設定を追加

```ruby
# config/initializers/moderation.rb
Moderation::Providers.load_providers!
```

### 3. 環境変数で選択

```bash
MODERATION_PROVIDER=my_provider
```

## API エンドポイント

### 主催者向けモデレーション管理

| Method | Path | 説明 |
|--------|------|------|
| GET | `/organizers/contests/:contest_id/moderation` | モデレーションダッシュボード |
| PATCH | `/organizers/contests/:contest_id/moderation/:id/approve` | エントリー承認 |
| PATCH | `/organizers/contests/:contest_id/moderation/:id/reject` | エントリー却下 |

## ビューコンポーネント

### ステータスバッジ

```erb
<%# 主催者向け: app/views/organizers/entries/show.html.erb %>
<% case @entry.moderation_status %>
<% when "moderation_pending" %>
  <span class="bg-yellow-100 text-yellow-800">確認待ち</span>
<% when "moderation_approved" %>
  <span class="bg-green-100 text-green-800">承認済み</span>
<% when "moderation_hidden" %>
  <span class="bg-red-100 text-red-800">非表示</span>
<% when "moderation_requires_review" %>
  <span class="bg-orange-100 text-orange-800">要確認</span>
<% end %>
```

### 投稿者向け通知

```erb
<%# app/views/entries/show.html.erb %>
<% if @entry.moderation_hidden? %>
  <div class="bg-red-50 border border-red-200">
    この応募は非表示になっています
  </div>
<% elsif @entry.moderation_requires_review? %>
  <div class="bg-orange-50 border border-orange-200">
    この応募は確認中です
  </div>
<% end %>
```

## テスト

### モデルテスト

```bash
bundle exec rspec spec/models/moderation_result_spec.rb
bundle exec rspec spec/models/entry_spec.rb -e "moderation"
bundle exec rspec spec/models/contest_spec.rb -e "moderation"
```

### サービステスト

```bash
bundle exec rspec spec/services/moderation/
```

### コントローラーテスト

```bash
bundle exec rspec spec/requests/organizers/moderation_spec.rb
```

### 全テスト

```bash
bundle exec rspec
```

## トラブルシューティング

### AWS認証エラー

```
Aws::Rekognition::Errors::UnrecognizedClientException
```

→ AWS認証情報を確認してください。

### プロバイダー未設定エラー

```
Moderation::Providers::ProviderNotConfiguredError
```

→ `MODERATION_PROVIDER` 環境変数を設定してください。

### ジョブが実行されない

1. Sidekiqが起動しているか確認
2. `moderation` キューが設定されているか確認
3. `contest.moderation_enabled?` が `true` か確認

## 関連ファイル

```
app/
├── controllers/
│   └── organizers/
│       └── moderation_controller.rb
├── jobs/
│   └── moderation_job.rb
├── models/
│   ├── entry.rb              # moderation_status追加
│   ├── contest.rb            # moderation設定追加
│   └── moderation_result.rb
├── services/
│   └── moderation/
│       ├── moderation_service.rb
│       ├── providers.rb
│       └── providers/
│           ├── base_provider.rb
│           └── rekognition_provider.rb
├── views/
│   └── organizers/
│       └── moderation/
│           ├── index.html.erb
│           ├── _entry.html.erb
│           ├── approve.turbo_stream.erb
│           └── reject.turbo_stream.erb
└── javascript/
    └── controllers/
        └── moderation_settings_controller.js

config/
└── initializers/
    └── moderation.rb

db/migrate/
├── xxx_create_moderation_results.rb
├── xxx_add_moderation_status_to_entries.rb
└── xxx_add_moderation_settings_to_contests.rb

spec/
├── factories/
│   └── moderation_results.rb
├── models/
│   └── moderation_result_spec.rb
├── services/
│   └── moderation/
│       ├── moderation_service_spec.rb
│       └── providers/
│           └── rekognition_provider_spec.rb
├── jobs/
│   └── moderation_job_spec.rb
└── requests/
    └── organizers/
        └── moderation_spec.rb
```
