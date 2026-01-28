# Requirements Document: 審査・ランキング機能

## Introduction

コンテスト応募作品を審査し、ランキングを決定・発表するための機能。審査員による専門的な評価と一般投票を組み合わせた柔軟な審査方式を提供し、公正で透明性のある審査プロセスを実現する。入賞作品の発表機能も含み、コンテストの結果を効果的に共有できるようにする。

## Alignment with Product Vision

この機能は以下のプロダクトビジョンを実現する：
- **審査・投票システム**: 審査員評価と一般投票を組み合わせた柔軟な審査方式（Key Feature #4）
- **結果発表・展示**: 入賞作品の発表、オンラインギャラリー、地域PRへの活用支援（Key Feature #5）
- **地域の魅力発信**: 優秀作品を通じた地域PRコンテンツの創出（Business Objective）

## Requirements

### Requirement 1: 審査員管理

**User Story:** As a 主催者, I want 審査員をコンテストに招待・管理できる, so that 専門家による公正な審査を実施できる

#### Acceptance Criteria

1. WHEN 主催者がコンテスト詳細画面で「審査員管理」を選択 THEN システムは審査員一覧画面を表示SHALL
2. WHEN 主催者が審査員追加フォームにメールアドレスを入力して送信 THEN システムは招待メールを送信し、審査員候補をリストに追加SHALL
3. IF 招待されたユーザーがまだ登録していない THEN システムは新規登録を促す招待リンクを送信SHALL
4. WHEN 招待されたユーザーが招待を承諾 THEN システムはそのユーザーをコンテストの審査員として登録SHALL
5. WHEN 主催者が審査員を削除 THEN システムはその審査員のアクセス権を取り消しSHALL（既存の採点は保持）

### Requirement 2: 審査設定

**User Story:** As a 主催者, I want 審査方式と配点を設定できる, so that コンテストの目的に合った評価基準を設定できる

#### Acceptance Criteria

1. WHEN 主催者がコンテスト設定画面で審査設定を開く THEN システムは審査方式の選択肢（審査員のみ/投票のみ/ハイブリッド）を表示SHALL
2. WHEN 主催者が「ハイブリッド」を選択 THEN システムは審査員評価と投票の配分比率（例：70:30）を設定できるSHALL
3. WHEN 主催者が評価項目を設定 THEN システムは複数の評価項目（技術、構図、テーマ適合性等）とその配点を保存SHALL
4. IF コンテストが公開済み THEN 審査方式の変更は不可とし、配点の微調整のみ許可SHALL
5. WHEN 審査設定を保存 THEN システムは設定内容を検証し、配点合計が100%になることを確認SHALL

### Requirement 3: 審査員による採点

**User Story:** As a 審査員, I want 応募作品を評価・採点できる, so that 専門的な観点から作品を評価できる

#### Acceptance Criteria

1. WHEN 審査員がログインしてコンテスト審査画面を開く THEN システムは未採点の作品一覧を表示SHALL
2. WHEN 審査員が作品を選択 THEN システムは作品詳細と評価フォーム（各評価項目のスコア入力欄）を表示SHALL
3. WHEN 審査員がスコアを入力して送信 THEN システムはスコアを保存し、次の未採点作品を表示SHALL
4. IF 審査員が既に採点した作品を選択 THEN システムは既存のスコアを表示し、修正を許可SHALL（審査期間中のみ）
5. WHEN 審査員がコメントを入力 THEN システムはコメントを保存し、主催者に公開SHALL（参加者への公開は主催者設定による）

### Requirement 4: ランキング計算

**User Story:** As a 主催者, I want システムが自動的にランキングを計算してくれる, so that 公正で透明性のあるランキングを発表できる

#### Acceptance Criteria

1. WHEN 審査期間が終了 THEN システムは審査員スコアと投票数を設定された比率で合算し、総合スコアを計算SHALL
2. WHEN 同点が発生 THEN システムは投票数優先、次に審査員平均スコア、最後に投稿日時の順で順位を決定SHALL
3. WHEN 主催者がランキングプレビューを要求 THEN システムは現時点での暫定ランキングを表示SHALL（公開前）
4. IF 審査員が全作品を採点していない THEN システムは警告を表示し、採点率を表示SHALL
5. WHEN ランキング計算が完了 THEN システムは各作品の順位、総合スコア、内訳を保存SHALL

### Requirement 5: 結果発表

**User Story:** As a 主催者, I want 結果を公開・発表できる, so that 参加者と一般の人に入賞作品を披露できる

#### Acceptance Criteria

1. WHEN 主催者が結果発表画面を開く THEN システムはランキング一覧と発表設定オプションを表示SHALL
2. WHEN 主催者が入賞者数（1位〜3位等）を設定 THEN システムは入賞者を決定し、プレビューを表示SHALL
3. WHEN 主催者が「結果を公開」を押下 THEN システムは結果発表ページを公開し、参加者に通知SHALL
4. IF コンテストがまだ終了していない THEN 結果公開ボタンは無効化SHALL
5. WHEN 結果が公開された THEN システムは入賞作品を強調表示したギャラリーページを生成SHALL

### Requirement 6: 結果閲覧

**User Story:** As a 参加者, I want コンテスト結果を閲覧できる, so that 自分の順位と入賞作品を確認できる

#### Acceptance Criteria

1. WHEN 参加者が結果公開後のコンテストページを訪問 THEN システムは入賞作品と順位を表示SHALL
2. WHEN 参加者が自分の作品を確認 THEN システムは自分の順位、スコア、フィードバック（公開設定されている場合）を表示SHALL
3. WHEN 一般ユーザーが結果ページを閲覧 THEN システムは入賞作品のギャラリーを表示SHALL
4. IF 主催者が詳細スコアの公開を許可 THEN 参加者は各評価項目のスコア内訳を確認できるSHALL
5. WHEN 入賞作品をクリック THEN システムは作品詳細ページを表示し、入賞バッジを表示SHALL

### Requirement 7: SNS共有（結果）

**User Story:** As a 入賞者, I want 入賞結果をSNSで共有できる, so that 自分の成果を広くアピールできる

#### Acceptance Criteria

1. WHEN 入賞者が結果ページを閲覧 THEN システムは「入賞をシェア」ボタンを表示SHALL
2. WHEN 入賞者がシェアボタンをクリック THEN システムはX、Facebook、LINEの共有オプションを表示SHALL
3. WHEN 共有リンクが生成される THEN システムは入賞情報を含むOGPメタタグを設定SHALL
4. IF 作品オーナーでないユーザーがシェア THEN 入賞作品として紹介する形式でシェアSHALL

## Non-Functional Requirements

### Code Architecture and Modularity
- **Single Responsibility Principle**: 審査、ランキング計算、結果発表は別々のサービスクラスに分離
- **Modular Design**: 審査方式（審査員/投票/ハイブリッド）はストラテジーパターンで実装
- **Dependency Management**: ランキング計算ロジックはモデルから独立したサービスとして実装
- **Clear Interfaces**: 審査員APIと主催者APIは明確に分離

### Performance
- ランキング計算は1000作品以内で5秒以内に完了すること
- 審査画面の作品読み込みは2秒以内
- 結果ページの初期表示は3秒以内

### Security
- 審査員は担当コンテストの作品のみ閲覧・採点可能
- 審査スコアは結果発表まで参加者に非公開
- 審査員の採点内容は匿名化オプションを提供

### Reliability
- 審査スコアは入力後即座にデータベースに保存
- ランキング計算は再計算可能（主催者による修正対応）
- 結果発表後の変更は監査ログに記録

### Usability
- 審査員向け採点UIは直感的で、大量の作品を効率的に採点可能
- モバイルでも審査作業が可能
- ランキング・結果はグラフやバッジで視覚的に表示
