# Technology Stack

## Project Type
地域限定写真コンテストの支援・管理を行うWebアプリケーション。主催者向け管理画面と参加者向け応募・閲覧画面を提供する。

## Core Technologies

### Primary Language(s)
- **Language**: Ruby 3.3
- **Runtime**: Ruby MRI
- **Language-specific tools**: Bundler, RubyGems

### Key Dependencies/Libraries
- **Ruby on Rails 7.1**: フルスタックWebフレームワーク
- **Hotwire (Turbo + Stimulus)**: モダンなフロントエンド体験（SPA不要）
- **Active Storage**: ファイルアップロード・画像管理
- **Action Cable**: WebSocket通信（リアルタイム更新）
- **Devise**: 認証機能
- **ImageMagick / libvips**: 画像処理・リサイズ

### Application Architecture
Rails標準のMVCアーキテクチャ。Hotwireを活用してサーバーサイドレンダリング中心のモダンUI体験を実現。Turbo Framesによる部分更新、Turbo Streamsによるリアルタイム更新を活用。

### Data Storage (if applicable)
- **Primary storage**: SQLite（開発・小規模運用）/ PostgreSQL（本番運用）
- **File storage**: Active Storage（ローカルディスク / S3互換ストレージ）
- **Data formats**: JSON（API）、画像ファイル（JPEG, PNG, WebP）

### External Integrations (if applicable)
- **APIs**: 地図API（OpenStreetMap / Google Maps）撮影場所表示用
- **Protocols**: HTTP/REST
- **Authentication**: Devise（主催者認証）、セッションベーストークン（参加者）

### Monitoring & Dashboard Technologies (if applicable)
- **Dashboard Framework**: Rails ERB/ViewComponent + Hotwire
- **Real-time Communication**: Action Cable（WebSocket）/ Turbo Streams
- **Visualization Libraries**: Chartkick + Chart.js（統計グラフ）
- **State Management**: サーバーサイド中心（Hotwire）

## Development Environment

### Build & Development Tools
- **Build System**: Rails built-in（Asset Pipeline / Propshaft）
- **Package Management**: Bundler（Ruby）、Importmap（JavaScript）
- **Development workflow**: rails server（自動リロード対応）

### Code Quality Tools
- **Static Analysis**: RuboCop, Brakeman（セキュリティ）
- **Formatting**: RuboCop
- **Testing Framework**: RSpec（単体・統合テスト）、Capybara（システムテスト）
- **Documentation**: YARD、README.md

### Version Control & Collaboration
- **VCS**: Git
- **Branching Strategy**: GitHub Flow（main + feature branches）
- **Code Review Process**: Pull Request必須

### Dashboard Development (if applicable)
- **Live Reload**: Rails開発サーバー自動リロード
- **Port Management**: 環境変数で設定可能（デフォルト3000）
- **Multi-Instance Support**: 不要（単一インスタンス運用）

## Deployment & Distribution (if applicable)
- **Target Platform(s)**: クラウド（Heroku、Render、AWS）またはオンプレミスサーバー
- **Distribution Method**: Dockerイメージまたは直接デプロイ
- **Installation Requirements**: Ruby 3.3+、データベース（SQLite/PostgreSQL）、ImageMagick
- **Update Mechanism**: Gitプル + bundle install + マイグレーション、またはDockerイメージ更新

## Technical Requirements & Constraints

### Performance Requirements
- ページ読み込み: 3秒以内
- 画像アップロード: 10MB/枚まで対応
- 同時接続: 100ユーザー程度を想定

### Compatibility Requirements
- **Platform Support**: モダンブラウザ（Chrome, Firefox, Safari, Edge最新2バージョン）
- **Dependency Versions**: Ruby 3.3+, Rails 7.1+
- **Standards Compliance**: Web標準、アクセシビリティ（WCAG 2.1 AA目標）

### Security & Compliance
- **Security Requirements**: HTTPS必須、Rails標準のCSRF/XSS対策、Strong Parameters
- **Compliance Standards**: 個人情報保護法対応（必要に応じて）
- **Threat Model**: 不正投稿防止、なりすまし投票防止

### Scalability & Reliability
- **Expected Load**: コンテスト1件あたり〜1000応募を想定
- **Availability Requirements**: 99%稼働（コンテスト期間中）
- **Growth Projections**: 将来的に複数コンテスト同時開催対応

## Technical Decisions & Rationale

### Decision Log
1. **Ruby on Rails選択**: フルスタックで統一的な開発体験、Convention over Configurationによる高速開発
2. **Hotwire採用**: SPAフレームワーク不要でモダンなUI体験を実現、Rails統合が優秀
3. **SQLite/PostgreSQL**: 小規模ならSQLiteで簡単運用、スケール時はPostgreSQLへ移行可能

## Known Limitations

- **SQLite**: 高負荷時の同時書き込みに制限あり（PostgreSQL移行で解決）
- **Action Cable**: 大規模WebSocket接続時はRedisアダプター必要
