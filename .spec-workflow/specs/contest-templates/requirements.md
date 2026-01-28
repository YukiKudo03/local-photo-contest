# Requirements Document: Contest Templates

## Introduction

コンテストテンプレート機能は、主催者が過去に作成したコンテストの設定を再利用できるようにする機能です。毎回同じような設定を入力する手間を省き、コンテスト作成の効率を大幅に向上させます。

## Alignment with Product Vision

この機能は product.md の以下の目標に合致しています：
- **主催者のユーザビリティ向上**: コンテスト作成の手間を削減
- **継続的なコンテスト運営の支援**: 定期開催コンテストの設定を簡単に再利用

## Requirements

### Requirement 1: テンプレート保存

**User Story:** 主催者として、既存のコンテスト設定をテンプレートとして保存したい。そうすることで、将来のコンテスト作成を効率化できる。

#### Acceptance Criteria

1. WHEN 主催者がコンテスト詳細ページで「テンプレートとして保存」をクリック THEN システム SHALL テンプレート作成画面を表示
2. WHEN テンプレート作成画面が表示される THEN システム SHALL テンプレート名の入力フィールドを表示
3. WHEN 主催者がテンプレート名を入力して保存 THEN システム SHALL コンテストの設定をテンプレートとして保存
4. WHEN テンプレート保存が成功 THEN システム SHALL 成功メッセージを表示
5. IF テンプレート名が空 THEN システム SHALL エラーメッセージを表示して保存を拒否

### Requirement 2: テンプレートから新規コンテスト作成

**User Story:** 主催者として、保存したテンプレートから新しいコンテストを作成したい。そうすることで、設定入力の時間を大幅に短縮できる。

#### Acceptance Criteria

1. WHEN 主催者がコンテスト新規作成画面を表示 THEN システム SHALL 「テンプレートから作成」オプションを表示
2. WHEN 主催者が「テンプレートから作成」を選択 THEN システム SHALL 利用可能なテンプレート一覧を表示
3. WHEN 主催者がテンプレートを選択 THEN システム SHALL テンプレートの設定をフォームにプリセット
4. WHEN テンプレートがプリセットされる THEN システム SHALL 日付フィールドは空のままにする
5. WHEN 主催者がフォームを編集して保存 THEN システム SHALL 新しいコンテストを作成
6. IF 主催者がテンプレートを所有していない THEN システム SHALL 「テンプレートから作成」オプションを非表示

### Requirement 3: テンプレート一覧管理

**User Story:** 主催者として、保存したテンプレートを一覧で確認・管理したい。そうすることで、テンプレートを整理できる。

#### Acceptance Criteria

1. WHEN 主催者がテンプレート一覧ページにアクセス THEN システム SHALL 主催者のテンプレートを一覧表示
2. WHEN テンプレート一覧を表示 THEN システム SHALL 各テンプレートの名前、作成日、元コンテスト名を表示
3. WHEN 主催者がテンプレートの削除をクリック THEN システム SHALL 確認ダイアログを表示
4. WHEN 主催者が削除を確認 THEN システム SHALL テンプレートを削除
5. IF 他の主催者のテンプレートにアクセス THEN システム SHALL アクセスを拒否

### Requirement 4: テンプレートに保存される設定項目

**User Story:** 主催者として、コンテストの主要な設定がテンプレートに保存されることを期待する。そうすることで、毎回同じ設定を入力する必要がなくなる。

#### Acceptance Criteria

1. WHEN テンプレートが保存される THEN システム SHALL 以下の設定を保存:
   - テーマ (theme)
   - 説明 (description)
   - 審査方法 (judging_method)
   - 審査員配点比率 (judge_weight) ※hybrid の場合
   - 入賞者数 (prize_count)
   - モデレーション有効化フラグ (moderation_enabled)
   - モデレーション閾値 (moderation_threshold)
   - スポット必須フラグ (require_spot)
   - エリア (area_id)
   - カテゴリー (category_id)
2. WHEN テンプレートが保存される THEN システム SHALL 以下の項目は保存しない:
   - タイトル (title)
   - 応募開始日 (entry_start_at)
   - 応募終了日 (entry_end_at)
   - ステータス (status)

### Requirement 5: アクセス制御

**User Story:** 主催者として、自分のテンプレートは自分だけが利用・管理できることを期待する。

#### Acceptance Criteria

1. WHEN 非認証ユーザーがテンプレート機能にアクセス THEN システム SHALL ログインページにリダイレクト
2. WHEN 一般ユーザー（主催者でない）がテンプレート機能にアクセス THEN システム SHALL アクセスを拒否
3. WHEN 主催者がテンプレート一覧を表示 THEN システム SHALL 自分のテンプレートのみ表示
4. WHEN 主催者が他者のテンプレートを操作しようとする THEN システム SHALL アクセスを拒否

## Non-Functional Requirements

### Code Architecture and Modularity
- **Single Responsibility Principle**: ContestTemplate モデルはテンプレートデータの永続化に専念
- **Modular Design**: テンプレート機能は Organizers 名前空間内で独立して実装
- **Dependency Management**: 既存の Contest モデルとの疎結合を維持
- **Clear Interfaces**: TemplateService でテンプレート操作ロジックをカプセル化

### Performance
- テンプレート一覧の表示は 200ms 以内に完了
- テンプレートからのコンテスト作成は追加の遅延なく実行

### Security
- 主催者は自分のテンプレートのみアクセス可能
- テンプレート操作は認証・認可チェックを必須とする

### Reliability
- テンプレート保存時にトランザクションを使用
- テンプレート削除時にコンテストへの影響なし

### Usability
- テンプレート名は分かりやすく識別可能
- テンプレートから作成時、どの項目がプリセットされたか明確に表示
