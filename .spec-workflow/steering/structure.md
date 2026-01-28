# Project Structure

## Directory Organization

```
local-photo-contest/
├── app/                        # アプリケーションコード
│   ├── controllers/            # コントローラー
│   │   ├── concerns/           # 共通コントローラーロジック
│   │   ├── admin/              # システム管理者向けコントローラー
│   │   ├── organizers/         # 運営者（コンテスト主催者）向けコントローラー
│   │   ├── participants/       # 一般コンテスト参加者向けコントローラー
│   │   ├── public/             # 一般サイト訪問者向けコントローラー（認証不要）
│   │   └── api/                # API用コントローラー
│   ├── models/                 # モデル（ActiveRecord）
│   │   └── concerns/           # 共通モデルロジック
│   ├── views/                  # ビュー（ERB）
│   │   ├── layouts/            # レイアウトテンプレート
│   │   ├── shared/             # 共通パーシャル
│   │   └── components/         # ViewComponent
│   ├── helpers/                # ビューヘルパー
│   ├── javascript/             # JavaScript（Stimulus controllers）
│   │   └── controllers/        # Stimulusコントローラー
│   ├── assets/                 # アセット
│   │   ├── stylesheets/        # CSS/SCSS
│   │   └── images/             # 画像
│   ├── jobs/                   # バックグラウンドジョブ
│   ├── mailers/                # メーラー
│   └── channels/               # Action Cableチャンネル
├── config/                     # 設定ファイル
│   ├── environments/           # 環境別設定
│   ├── initializers/           # 初期化スクリプト
│   ├── locales/                # 国際化ファイル（日本語対応）
│   └── routes.rb               # ルーティング定義
├── db/                         # データベース
│   ├── migrate/                # マイグレーションファイル
│   └── seeds.rb                # シードデータ
├── lib/                        # ライブラリコード
│   └── tasks/                  # Rakeタスク
├── public/                     # 静的ファイル
├── storage/                    # Active Storageファイル保存
├── spec/                       # RSpecテスト
│   ├── models/                 # モデルテスト
│   ├── requests/               # リクエストテスト
│   ├── system/                 # システムテスト（Capybara）
│   ├── factories/              # FactoryBot定義
│   └── support/                # テストヘルパー
├── vendor/                     # サードパーティコード
└── .spec-workflow/             # 仕様管理
    └── steering/               # ステアリング文書
```

## Naming Conventions

### Files
- **Controllers**: `snake_case_controller.rb`（例: `contests_controller.rb`）
- **Models**: `snake_case.rb`（例: `photo_entry.rb`）
- **Views**: `action_name.html.erb`（例: `index.html.erb`）
- **Helpers**: `snake_case_helper.rb`（例: `contests_helper.rb`）
- **Tests**: `snake_case_spec.rb`（例: `contest_spec.rb`）
- **Stimulus**: `snake_case_controller.js`（例: `voting_controller.js`）

### Code
- **Classes/Modules**: `PascalCase`（例: `PhotoEntry`, `Admin::ContestsController`）
- **Methods**: `snake_case`（例: `submit_entry`, `calculate_votes`）
- **Constants**: `UPPER_SNAKE_CASE`（例: `MAX_FILE_SIZE`, `ALLOWED_FORMATS`）
- **Variables**: `snake_case`（例: `current_contest`, `photo_count`）
- **Database tables**: `snake_case`複数形（例: `contests`, `photo_entries`）
- **Database columns**: `snake_case`（例: `created_at`, `location_name`）

## Import Patterns

### Ruby Require/Load
Railsの自動読み込み（Zeitwerk）を使用。明示的なrequireは基本不要。

### Import Order（明示的に必要な場合）
1. 標準ライブラリ
2. Gem（外部ライブラリ）
3. アプリケーションコード

### JavaScript (Stimulus)
```javascript
// Stimulusコントローラーは自動読み込み
// app/javascript/controllers/index.js で管理
import { application } from "controllers/application"
import VotingController from "./voting_controller"
application.register("voting", VotingController)
```

## Code Structure Patterns

### Controller Organization
```ruby
class ContestsController < ApplicationController
  # 1. フィルター・コールバック
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_contest, only: [:show, :edit, :update, :destroy]

  # 2. 公開アクション（RESTful順）
  def index; end
  def show; end
  def new; end
  def create; end
  def edit; end
  def update; end
  def destroy; end

  private

  # 3. プライベートメソッド
  def set_contest; end
  def contest_params; end
end
```

### Model Organization
```ruby
class Contest < ApplicationRecord
  # 1. 関連付け
  has_many :photo_entries, dependent: :destroy
  belongs_to :organizer, class_name: "User"

  # 2. バリデーション
  validates :title, presence: true, length: { maximum: 100 }
  validates :region, presence: true

  # 3. スコープ
  scope :active, -> { where(status: :active) }
  scope :in_region, ->(region) { where(region: region) }

  # 4. コールバック
  before_save :normalize_region

  # 5. クラスメソッド
  def self.search(query); end

  # 6. インスタンスメソッド
  def accepting_entries?; end
  def vote_count; end

  private

  # 7. プライベートメソッド
  def normalize_region; end
end
```

### View Organization
```erb
<%# 1. ローカル変数・設定 %>
<% content_for :title, @contest.title %>

<%# 2. メインコンテンツ %>
<main>
  <%= render "contests/header", contest: @contest %>
  <%= yield %>
</main>

<%# 3. パーシャル呼び出し %>
<%= render "shared/footer" %>
```

## Code Organization Principles

1. **Single Responsibility**: 1つのクラス・メソッドは1つの責務
2. **Fat Model, Skinny Controller**: ビジネスロジックはモデルに
3. **DRY (Don't Repeat Yourself)**: 共通処理はconcernsやhelperに抽出
4. **Convention over Configuration**: Rails規約に従う

## Module Boundaries

### 名前空間による分離
- `Admin::` - システム管理者向け機能（ユーザー管理、システム設定等）
- `Organizers::` - 運営者向け機能（コンテスト作成・管理、審査等）
- `Participants::` - 参加者向け機能（応募、投票、マイページ等）
- `Public::` - 一般訪問者向け機能（コンテスト閲覧、ギャラリー等）
- `Api::` - API専用機能

### レイヤー構造
```
Controllers（入力処理）
    ↓
Models/Services（ビジネスロジック）
    ↓
Views（出力処理）
```

### 依存関係ルール
- ControllersはModelsに依存
- ViewsはModels/Helpersに依存
- ModelsはActiveRecordのみに依存
- ServicesはModelsに依存可能

## Code Size Guidelines

- **ファイルサイズ**: 最大300行（超える場合は分割検討）
- **メソッドサイズ**: 最大20行（超える場合はリファクタリング）
- **クラス複雑度**: 最大10メソッド（超える場合は責務分割）
- **ネスト深度**: 最大3レベル

## Documentation Standards

- **モデル**: 各カラムの意味、関連付けの説明
- **コントローラー**: 各アクションの役割
- **複雑なロジック**: インラインコメントで意図を説明
- **API**: OpenAPI/Swagger形式でドキュメント化
- **日本語対応**: コメントは日本語可、変数名・メソッド名は英語
