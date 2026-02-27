# システム設計図

本ドキュメントでは、Local Photo Contest システムの設計図を Mermaid 形式で提供します。

---

## 目次

1. [ユースケース図](#ユースケース図)
2. [ER図（エンティティ関連図）](#er図エンティティ関連図)
3. [シーケンス図](#シーケンス図)
   - [ユーザー登録・ログイン](#ユーザー登録ログイン)
   - [コンテスト作成](#コンテスト作成)
   - [作品応募](#作品応募)
   - [コンテンツモデレーション](#コンテンツモデレーション)
   - [投票](#投票)
   - [審査員評価](#審査員評価)
   - [結果発表](#結果発表)

---

## ユースケース図

```mermaid
flowchart TB
    subgraph Actors
        P((参加者<br/>Participant))
        O((主催者<br/>Organizer))
        J((審査員<br/>Judge))
        A((管理者<br/>Admin))
        S((システム<br/>System))
    end

    subgraph "参加者のユースケース"
        UC1[コンテスト一覧を閲覧]
        UC2[コンテスト詳細を閲覧]
        UC3[作品を応募]
        UC4[自分の作品を編集/削除]
        UC5[他の作品に投票]
        UC6[作品にコメント]
        UC7[ギャラリーを閲覧]
        UC8[結果を確認]
        UC9[通知を確認]
        UC10[プロフィールを編集]
        UC29[スポットを発見・投票]
        UC30[チャレンジに参加]
        UC31[作品を検索]
        UC32[言語を切り替え]
        UC33[チュートリアルを利用]
        UC34[ヘルプを参照]
    end

    subgraph "主催者のユースケース"
        UC11[コンテストを作成]
        UC12[コンテストを編集]
        UC13[コンテストを公開]
        UC14[コンテストを終了]
        UC15[結果を発表]
        UC16[エリアを管理]
        UC17[スポットを管理]
        UC18[審査員を招待]
        UC19[評価基準を設定]
        UC20[応募作品を管理]
        UC21[モデレーション結果を確認]
        UC22[作品を承認/却下]
        UC35[テンプレートを管理]
        UC36[統計を確認・エクスポート]
        UC37[発見スポットを認定/却下]
        UC38[チャレンジを作成・管理]
    end

    subgraph "審査員のユースケース"
        UC23[担当コンテストを確認]
        UC24[作品を評価]
        UC25[審査コメントを記入]
        UC39[招待を受諾/辞退]
    end

    subgraph "管理者のユースケース"
        UC40[ユーザーを管理]
        UC41[カテゴリを管理]
        UC42[監査ログを確認]
        UC43[チュートリアル分析]
    end

    subgraph "システムのユースケース"
        UC26[画像をモデレート]
        UC27[通知を送信]
        UC28[ランキングを計算]
        UC44[EXIF情報を抽出]
        UC45[日次ダイジェストを送信]
    end

    P --> UC1
    P --> UC2
    P --> UC3
    P --> UC4
    P --> UC5
    P --> UC6
    P --> UC7
    P --> UC8
    P --> UC9
    P --> UC10
    P --> UC29
    P --> UC30
    P --> UC31
    P --> UC32
    P --> UC33
    P --> UC34

    O --> UC11
    O --> UC12
    O --> UC13
    O --> UC14
    O --> UC15
    O --> UC16
    O --> UC17
    O --> UC18
    O --> UC19
    O --> UC20
    O --> UC21
    O --> UC22
    O --> UC35
    O --> UC36
    O --> UC37
    O --> UC38

    J --> UC23
    J --> UC24
    J --> UC25
    J --> UC39

    A --> UC40
    A --> UC41
    A --> UC42
    A --> UC43

    S --> UC26
    S --> UC27
    S --> UC28
    S --> UC44
    S --> UC45

    UC3 -.->|トリガー| UC26
    UC3 -.->|トリガー| UC44
    UC15 -.->|トリガー| UC27
    UC5 -.->|トリガー| UC28
```

### アクター別ユースケース一覧

| アクター | ユースケース |
|---------|-------------|
| 参加者 | コンテスト閲覧、作品応募、投票、コメント、通知確認、スポット発見・投票、チャレンジ参加、検索、チュートリアル、ヘルプ |
| 主催者 | コンテスト管理、エリア/スポット管理、審査員招待、モデレーション、テンプレート管理、統計分析、発見スポット認定、チャレンジ管理 |
| 審査員 | 招待受諾/辞退、作品評価、審査コメント記入 |
| 管理者 | ユーザー管理、カテゴリ管理、監査ログ、チュートリアル分析 |
| システム | 画像モデレーション、通知送信、ランキング計算、EXIF抽出、日次ダイジェスト |

---

## ER図（エンティティ関連図）

```mermaid
erDiagram
    User ||--o{ Contest : "creates"
    User ||--o{ Entry : "submits"
    User ||--o{ Vote : "casts"
    User ||--o{ Comment : "writes"
    User ||--o{ Notification : "receives"
    User ||--o{ ContestJudge : "assigned as"
    User ||--o{ Area : "manages"
    User ||--o{ TermsAcceptance : "accepts"
    User ||--o{ Spot : "discovers"
    User ||--o{ SpotVote : "casts"
    User ||--o{ DiscoveryBadge : "earns"
    User ||--o{ TutorialProgress : "tracks"
    User ||--o{ UserMilestone : "achieves"
    User ||--o{ FeatureUnlock : "unlocks"

    Contest ||--o{ Entry : "has"
    Contest ||--o{ Spot : "has"
    Contest ||--o{ ContestJudge : "has"
    Contest ||--o{ EvaluationCriterion : "has"
    Contest ||--o{ ContestRanking : "has"
    Contest ||--o{ JudgeInvitation : "has"
    Contest ||--o{ DiscoveryChallenge : "has"
    Contest ||--o{ DiscoveryBadge : "awards"
    Contest ||--o{ ContestTemplate : "source of"
    Contest }o--|| Category : "belongs to"
    Contest }o--|| Area : "held in"

    Entry ||--o{ Vote : "receives"
    Entry ||--o{ Comment : "has"
    Entry ||--o{ JudgeEvaluation : "evaluated by"
    Entry ||--o{ JudgeComment : "commented by"
    Entry ||--o| ModerationResult : "has"
    Entry ||--o| ContestRanking : "ranked as"
    Entry ||--o{ ChallengeEntry : "participates in"
    Entry }o--|| Spot : "taken at"
    Entry }o--|| Area : "located in"

    Spot ||--o{ SpotVote : "receives"
    Spot ||--o{ Entry : "has"

    ContestJudge ||--o{ JudgeEvaluation : "makes"
    ContestJudge ||--o{ JudgeComment : "writes"

    JudgeEvaluation }o--|| EvaluationCriterion : "based on"

    DiscoveryChallenge ||--o{ ChallengeEntry : "has"

    TermsAcceptance }o--|| TermsOfService : "for"

    User {
        integer id PK
        string email UK
        string encrypted_password
        integer role "participant/organizer/admin"
        string name
        text bio
        string locale "ja/en"
        json tutorial_settings
        integer feature_level
        boolean email_on_entry_submitted
        boolean email_on_comment
        boolean email_on_vote
        boolean email_on_results
        boolean email_digest
        boolean email_on_judging
        string unsubscribe_token
        datetime confirmed_at
        datetime locked_at
    }

    Contest {
        integer id PK
        integer user_id FK
        integer category_id FK
        integer area_id FK
        string title
        text description
        string theme
        integer status "draft/published/finished"
        datetime entry_start_at
        datetime entry_end_at
        datetime results_announced_at
        boolean moderation_enabled
        decimal moderation_threshold
        integer judging_method "judge_only/vote_only/hybrid"
        integer judge_weight
        integer prize_count
        boolean require_spot
        boolean show_detailed_scores
        datetime deleted_at
    }

    Entry {
        integer id PK
        integer user_id FK
        integer contest_id FK
        integer area_id FK
        integer spot_id FK
        string title
        text description
        string location
        date taken_at
        decimal latitude
        decimal longitude
        integer location_source "manual/exif/gps"
        integer moderation_status "pending/approved/hidden/requires_review"
        json exif_data
    }

    Spot {
        integer id PK
        integer contest_id FK
        integer discovered_by_id FK
        integer certified_by_id FK
        integer merged_into_id FK
        string name
        integer category
        string address
        decimal latitude
        decimal longitude
        text description
        integer discovery_status "organizer_created/discovered/certified/rejected"
        datetime discovered_at
        datetime certified_at
        string rejection_reason
        text discovery_comment
        integer votes_count
    }

    SpotVote {
        integer id PK
        integer user_id FK
        integer spot_id FK
    }

    ContestRanking {
        integer id PK
        integer contest_id FK
        integer entry_id FK
        integer rank
        decimal total_score
        decimal judge_score
        decimal vote_score
        integer vote_count
        datetime calculated_at
    }

    JudgeInvitation {
        integer id PK
        integer contest_id FK
        integer invited_by_id FK
        integer user_id FK
        string email
        string token
        integer status "pending/accepted/declined"
        datetime invited_at
        datetime responded_at
    }

    ContestTemplate {
        integer id PK
        integer user_id FK
        integer source_contest_id FK
        string name
        string theme
        integer judging_method
        integer judge_weight
        boolean moderation_enabled
        decimal moderation_threshold
    }

    DiscoveryChallenge {
        integer id PK
        integer contest_id FK
        string name
        text description
        string theme
        datetime starts_at
        datetime ends_at
        integer status "draft/active/finished"
    }

    ChallengeEntry {
        integer id PK
        integer discovery_challenge_id FK
        integer entry_id FK
    }

    DiscoveryBadge {
        integer id PK
        integer user_id FK
        integer contest_id FK
        integer badge_type "explorer/curator"
        datetime earned_at
        json metadata
    }

    Vote {
        integer id PK
        integer user_id FK
        integer entry_id FK
    }

    Comment {
        integer id PK
        integer user_id FK
        integer entry_id FK
        text body
    }

    ModerationResult {
        integer id PK
        integer entry_id FK
        integer reviewed_by_id FK
        string provider
        integer status "pending/approved/rejected/requires_review"
        json labels
        decimal max_confidence
        json raw_response
        datetime reviewed_at
        text review_note
    }

    Category {
        integer id PK
        string name UK
        text description
        integer position
    }

    Area {
        integer id PK
        integer user_id FK
        string name
        string prefecture
        string city
        string address
        decimal latitude
        decimal longitude
        text boundary_geojson
    }

    ContestJudge {
        integer id PK
        integer contest_id FK
        integer user_id FK
        datetime invited_at
    }

    EvaluationCriterion {
        integer id PK
        integer contest_id FK
        string name
        text description
        integer position
        integer max_score
    }

    JudgeEvaluation {
        integer id PK
        integer contest_judge_id FK
        integer entry_id FK
        integer evaluation_criterion_id FK
        integer score
    }

    JudgeComment {
        integer id PK
        integer contest_judge_id FK
        integer entry_id FK
        text comment
    }

    Notification {
        integer id PK
        integer user_id FK
        string notifiable_type
        integer notifiable_id
        string notification_type
        string title
        text body
        datetime read_at
    }

    TutorialStep {
        integer id PK
        string tutorial_type
        string step_id
        integer position
        string title
        string description
        string target_selector
        string target_path
        string tooltip_position
        string video_url
        string action_type
        string success_feedback
        integer recommended_duration
        boolean skippable
    }

    TutorialProgress {
        integer id PK
        integer user_id FK
        string tutorial_type
        string current_step_id
        boolean completed
        boolean skipped
        datetime started_at
        datetime completed_at
        json step_times
        json skipped_steps
        string completion_method
    }

    UserMilestone {
        integer id PK
        integer user_id FK
        string milestone_type
        datetime achieved_at
        json metadata
    }

    FeatureUnlock {
        integer id PK
        integer user_id FK
        string feature_key
        datetime unlocked_at
        string unlock_trigger
    }

    AuditLog {
        integer id PK
        integer user_id FK
        string action
        string target_type
        integer target_id
        text details
        string ip_address
    }

    TermsOfService {
        integer id PK
        string version UK
        text content
        datetime published_at
    }

    TermsAcceptance {
        integer id PK
        integer user_id FK
        integer terms_of_service_id FK
        datetime accepted_at
        string ip_address
    }
```

---

## シーケンス図

### ユーザー登録・ログイン

```mermaid
sequenceDiagram
    autonumber
    actor User as ユーザー
    participant Browser as ブラウザ
    participant Rails as Rails App
    participant Devise as Devise
    participant DB as データベース
    participant Mailer as メーラー

    Note over User,Mailer: 新規登録フロー
    User->>Browser: 登録画面にアクセス
    Browser->>Rails: GET /organizers/sign_up
    Rails-->>Browser: 登録フォーム表示

    User->>Browser: メール・パスワード入力
    Browser->>Rails: POST /organizers
    Rails->>Devise: create_user
    Devise->>DB: INSERT users
    DB-->>Devise: User created
    Devise->>Mailer: send_confirmation_email
    Mailer-->>User: 確認メール送信
    Rails-->>Browser: リダイレクト（確認待ち画面）

    User->>Browser: メール内リンクをクリック
    Browser->>Rails: GET /organizers/confirmation?token=xxx
    Rails->>Devise: confirm_user
    Devise->>DB: UPDATE users SET confirmed_at
    DB-->>Devise: User confirmed
    Rails-->>Browser: リダイレクト（ログイン画面）

    Note over User,Mailer: ログインフロー
    User->>Browser: ログイン画面にアクセス
    Browser->>Rails: GET /organizers/sign_in
    Rails-->>Browser: ログインフォーム表示

    User->>Browser: メール・パスワード入力
    Browser->>Rails: POST /organizers/sign_in
    Rails->>Devise: authenticate_user
    Devise->>DB: SELECT FROM users WHERE email = ?
    DB-->>Devise: User found

    alt 認証成功
        Devise->>DB: UPDATE users (sign_in_count, last_sign_in_at)
        Rails-->>Browser: リダイレクト（ダッシュボード）
    else 認証失敗
        Rails-->>Browser: エラー表示
    end
```

### コンテスト作成

```mermaid
sequenceDiagram
    autonumber
    actor Organizer as 主催者
    participant Browser as ブラウザ
    participant Rails as Rails App
    participant Controller as ContestsController
    participant Model as Contest Model
    participant DB as データベース

    Organizer->>Browser: コンテスト作成画面にアクセス
    Browser->>Rails: GET /organizers/contests/new
    Rails->>Controller: new
    Controller-->>Browser: 作成フォーム表示

    Organizer->>Browser: コンテスト情報入力
    Browser->>Rails: POST /organizers/contests
    Rails->>Controller: create
    Controller->>Model: new(contest_params)
    Model->>Model: validate

    alt バリデーション成功
        Model->>DB: INSERT contests
        DB-->>Model: Contest created
        Controller-->>Browser: リダイレクト（詳細画面）
    else バリデーション失敗
        Controller-->>Browser: エラー表示
    end

    Note over Organizer,DB: コンテスト公開フロー
    Organizer->>Browser: 公開ボタンをクリック
    Browser->>Rails: PATCH /organizers/contests/:id/publish
    Rails->>Controller: publish
    Controller->>Model: find(id)
    Model->>DB: SELECT FROM contests
    DB-->>Model: Contest found
    Controller->>Model: publish!
    Model->>Model: check status == draft?
    Model->>DB: UPDATE contests SET status = published
    DB-->>Model: Updated
    Controller-->>Browser: Turbo Stream更新
```

### 作品応募

```mermaid
sequenceDiagram
    autonumber
    actor Participant as 参加者
    participant Browser as ブラウザ
    participant Rails as Rails App
    participant Controller as EntriesController
    participant Model as Entry Model
    participant Storage as Active Storage
    participant DB as データベース
    participant Queue as Solid Queue
    participant Job as ModerationJob

    Participant->>Browser: 応募画面にアクセス
    Browser->>Rails: GET /contests/:id/entries/new
    Rails->>Controller: new
    Controller-->>Browser: 応募フォーム表示

    Participant->>Browser: 写真・情報を入力
    Browser->>Rails: POST /contests/:id/entries
    Rails->>Controller: create
    Controller->>Model: new(entry_params)

    Model->>Model: validate
    Model->>Model: contest_accepting_entries?
    Model->>Model: photo_content_type
    Model->>Model: photo_size

    alt バリデーション成功
        Model->>DB: INSERT entries
        DB-->>Model: Entry created
        Model->>Storage: attach photo
        Storage-->>Model: Photo attached
        Model->>Model: after_create_commit
        Model->>Queue: enqueue ModerationJob
        Queue-->>Model: Job queued
        Controller-->>Browser: リダイレクト（詳細画面）
    else バリデーション失敗
        Controller-->>Browser: エラー表示
    end

    Note over Queue,Job: 非同期モデレーション処理
    Queue->>Job: perform(entry_id)
    Job->>Job: Moderation::ModerationServiceを呼び出し
```

### コンテンツモデレーション

```mermaid
sequenceDiagram
    autonumber
    participant Queue as Solid Queue
    participant Job as ModerationJob
    participant Service as ModerationService
    participant Provider as RekognitionProvider
    participant AWS as AWS Rekognition
    participant Entry as Entry Model
    participant Result as ModerationResult
    participant DB as データベース

    Queue->>Job: perform(entry_id)
    Job->>Entry: find_by(id: entry_id)
    Entry->>DB: SELECT FROM entries
    DB-->>Entry: Entry found

    Job->>Service: moderate(entry)
    Service->>Service: check moderation_enabled?

    alt モデレーション無効
        Service-->>Job: ServiceResult(skipped)
    else モデレーション有効
        Service->>Entry: photo.download
        Entry-->>Service: image_data

        Service->>Provider: analyze(image_data, threshold)
        Provider->>AWS: detect_moderation_labels
        AWS-->>Provider: labels response

        Provider->>Provider: parse_response
        Provider-->>Service: AnalysisResult

        Service->>Result: create
        Result->>DB: INSERT moderation_results
        DB-->>Result: Created

        alt 閾値超え検出
            Service->>Entry: update(moderation_status: hidden)
        else 閾値内
            Service->>Entry: update(moderation_status: approved)
        end

        Entry->>DB: UPDATE entries
        DB-->>Entry: Updated

        Service-->>Job: ServiceResult(success)
    end

    Job-->>Queue: Job completed

    Note over Queue,DB: 主催者による手動レビュー
    actor Organizer as 主催者
    participant ReviewController as ModerationController

    Organizer->>ReviewController: PATCH /approve
    ReviewController->>Entry: find(id)
    ReviewController->>Result: mark_reviewed!(approved: true)
    Result->>DB: UPDATE moderation_results
    ReviewController->>Entry: update(moderation_status: approved)
    Entry->>DB: UPDATE entries
    ReviewController-->>Organizer: Turbo Stream更新
```

### 投票

```mermaid
sequenceDiagram
    autonumber
    actor Participant as 参加者
    participant Browser as ブラウザ
    participant Rails as Rails App
    participant Controller as VotesController
    participant Vote as Vote Model
    participant Entry as Entry Model
    participant DB as データベース

    Participant->>Browser: 作品詳細画面を閲覧
    Browser->>Rails: GET /entries/:id
    Rails-->>Browser: 作品詳細表示（投票ボタンあり）

    Participant->>Browser: 投票ボタンをクリック
    Browser->>Rails: POST /entries/:id/vote
    Rails->>Controller: create

    Controller->>Vote: new(user: current_user, entry: entry)
    Vote->>Vote: validate
    Vote->>Vote: cannot_vote_own_entry
    Vote->>Vote: contest_accepting_votes

    alt バリデーション成功
        Vote->>DB: INSERT votes
        DB-->>Vote: Vote created
        Controller-->>Browser: Turbo Stream（投票数更新）
    else 自分の作品
        Controller-->>Browser: エラー「自分の作品には投票できません」
    else 重複投票
        Controller-->>Browser: エラー「既に投票済みです」
    end

    Note over Participant,DB: 投票取り消し
    Participant->>Browser: 投票取り消しボタンをクリック
    Browser->>Rails: DELETE /entries/:id/vote
    Rails->>Controller: destroy
    Controller->>Vote: find_by(user: current_user, entry: entry)
    Vote->>DB: DELETE FROM votes
    DB-->>Vote: Vote deleted
    Controller-->>Browser: Turbo Stream（投票数更新）
```

### 審査員評価

```mermaid
sequenceDiagram
    autonumber
    actor Judge as 審査員
    participant Browser as ブラウザ
    participant Rails as Rails App
    participant Controller as JudgeEvaluationsController
    participant CJ as ContestJudge
    participant JE as JudgeEvaluation
    participant JC as JudgeComment
    participant Entry as Entry
    participant DB as データベース

    Judge->>Browser: 審査割り当て一覧にアクセス
    Browser->>Rails: GET /my/judge_assignments
    Rails-->>Browser: 担当コンテスト一覧表示

    Judge->>Browser: コンテストを選択
    Browser->>Rails: GET /my/judge_assignments/:id
    Rails->>CJ: find(id)
    CJ->>DB: SELECT FROM contest_judges
    DB-->>CJ: ContestJudge found
    Rails-->>Browser: 作品一覧と評価フォーム表示

    Judge->>Browser: 作品を選択して評価入力
    Browser->>Rails: POST /my/judge_assignments/:id/evaluations
    Rails->>Controller: create

    loop 各評価基準
        Controller->>JE: find_or_initialize_by(criterion)
        JE->>JE: validate
        JE->>JE: score_within_max
        JE->>JE: cannot_evaluate_own_entry
        JE->>DB: UPSERT judge_evaluations
        DB-->>JE: Saved
    end

    Judge->>Browser: コメントを入力
    Browser->>Rails: POST /my/judge_assignments/:id/evaluations
    Controller->>JC: find_or_initialize_by(entry)
    JC->>DB: UPSERT judge_comments
    DB-->>JC: Saved

    Controller-->>Browser: Turbo Stream（評価完了表示）

    Note over Judge,DB: 評価進捗確認
    Judge->>Browser: 進捗を確認
    Rails->>CJ: evaluation_progress
    CJ->>CJ: count fully_evaluated entries
    CJ-->>Rails: progress percentage
    Rails-->>Browser: 進捗バー表示
```

### 結果発表

```mermaid
sequenceDiagram
    autonumber
    actor Organizer as 主催者
    participant Browser as ブラウザ
    participant Rails as Rails App
    participant Controller as ContestsController
    participant Contest as Contest Model
    participant Entry as Entry Model
    participant Notification as Notification Model
    participant DB as データベース

    Organizer->>Browser: コンテスト管理画面にアクセス
    Browser->>Rails: GET /organizers/contests/:id
    Rails-->>Browser: コンテスト詳細（結果発表ボタンあり）

    Organizer->>Browser: 結果発表ボタンをクリック
    Browser->>Rails: PATCH /organizers/contests/:id/announce_results
    Rails->>Controller: announce_results

    Controller->>Contest: find(id)
    Contest->>DB: SELECT FROM contests
    DB-->>Contest: Contest found

    Controller->>Contest: announce_results!
    Contest->>Contest: check finished?
    Contest->>Contest: check not results_announced?

    Contest->>DB: UPDATE contests SET results_announced_at
    DB-->>Contest: Updated

    Contest->>Contest: send_results_notifications
    Contest->>Entry: ranked_entries
    Entry->>DB: SELECT with vote counts
    DB-->>Entry: Ranked entries

    loop 各参加者
        Contest->>Notification: create_results_announced!
        Notification->>DB: INSERT notifications
        DB-->>Notification: Created
    end

    loop Top 3 入賞者
        Contest->>Notification: create_entry_ranked!
        Notification->>DB: INSERT notifications
        DB-->>Notification: Created
    end

    Controller-->>Browser: Turbo Stream（結果発表完了）

    Note over Organizer,DB: 参加者による結果確認
    actor Participant as 参加者

    Participant->>Browser: 結果ページにアクセス
    Browser->>Rails: GET /contests/:id/results
    Rails->>Contest: ranked_entries
    Rails->>Contest: judge_ranked_entries
    Rails-->>Browser: ランキング表示

    Participant->>Browser: 通知を確認
    Browser->>Rails: GET /my/notifications
    Rails->>Notification: where(user: current_user)
    Notification->>DB: SELECT FROM notifications
    DB-->>Notification: Notifications found
    Rails-->>Browser: 通知一覧表示
```

---

## 補足：状態遷移図

### コンテストの状態遷移

```mermaid
stateDiagram-v2
    [*] --> draft: 作成
    draft --> published: 公開
    draft --> [*]: 削除

    published --> finished: 終了
    finished --> results_announced: 結果発表

    note right of draft
        ・編集可能
        ・削除可能
    end note

    note right of published
        ・応募受付中
        ・投票受付中
        ・編集不可
    end note

    note right of finished
        ・応募終了
        ・投票終了
    end note

    note right of results_announced
        ・結果公開
        ・通知送信済み
    end note
```

### 作品のモデレーション状態遷移

```mermaid
stateDiagram-v2
    [*] --> pending: 作品投稿

    pending --> approved: 自動承認<br/>(問題なし)
    pending --> hidden: 自動非表示<br/>(閾値超え)
    pending --> requires_review: エラー発生

    hidden --> approved: 主催者が承認
    hidden --> hidden: 主催者が却下を維持

    requires_review --> approved: 主催者が承認
    requires_review --> hidden: 主催者が却下

    note right of pending
        ・投稿直後
        ・ギャラリー表示可
    end note

    note right of approved
        ・モデレーション通過
        ・ギャラリー表示可
    end note

    note right of hidden
        ・不適切コンテンツ検出
        ・ギャラリー非表示
        ・オーナーのみ閲覧可
    end note

    note right of requires_review
        ・要手動確認
        ・ギャラリー非表示
    end note
```

---

## ファイル構成との対応

| 図 | 関連ファイル |
|----|-------------|
| ユースケース図 | `config/routes.rb`, 各Controller |
| ER図 | `db/schema.rb`, `app/models/*.rb`, `app/models/concerns/*.rb` |
| ユーザー登録 | `app/controllers/organizers/registrations_controller.rb` |
| コンテスト作成 | `app/controllers/organizers/contests_controller.rb` |
| 作品応募 | `app/controllers/entries_controller.rb`, `app/models/concerns/moderatable.rb`, `app/models/concerns/entry_notifications.rb` |
| モデレーション | `app/jobs/moderation_job.rb`, `app/services/moderation/` |
| 投票 | `app/controllers/votes_controller.rb`, `app/controllers/spot_votes_controller.rb` |
| 審査員評価 | `app/controllers/my/judge_evaluations_controller.rb` |
| 結果発表 | `app/models/concerns/contest_state_machine.rb#announce_results!`, `app/services/ranking_calculator.rb` |
| スポット発見 | `app/services/discovery_spot_service.rb`, `app/controllers/organizers/discovery_spots_controller.rb` |
| 統計 | `app/services/statistics_service.rb`, `app/services/statistics_export_service.rb` |

---

*このドキュメントは Local Photo Contest v1.3 に基づいています（2026-02-28 更新）。*
