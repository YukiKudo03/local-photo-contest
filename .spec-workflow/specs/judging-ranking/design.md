# Design Document: 審査・ランキング機能

## Overview

既存の審査員管理・評価機能をベースに、審査方式選択（審査員のみ/投票のみ/ハイブリッド）、ランキング計算、結果発表機能を実装する。

## Architecture

### Design Approach

既存のモデル（ContestJudge、JudgeEvaluation、EvaluationCriterion）を拡張し、審査方式設定とハイブリッドランキング計算を追加する。ランキング計算はサービスクラスに分離し、ストラテジーパターンで審査方式ごとの計算ロジックを実装する。

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         Controllers                              │
├─────────────────────────────────────────────────────────────────┤
│  Organizers::                                                    │
│  ├── JudgingSettingsController (審査方式・配点設定)              │
│  ├── ResultsController (結果発表管理)                            │
│  └── ContestJudgesController (既存: 審査員管理)                  │
│                                                                  │
│  My::                                                            │
│  ├── JudgeEvaluationsController (既存: 審査員採点)               │
│  └── JudgeAssignmentsController (既存: 審査員ダッシュボード)     │
│                                                                  │
│  Contests::                                                      │
│  └── ResultsController (既存拡張: 結果閲覧)                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          Services                                │
├─────────────────────────────────────────────────────────────────┤
│  RankingCalculator (ランキング計算総合サービス)                  │
│  ├── JudgeOnlyRankingStrategy                                    │
│  ├── VoteOnlyRankingStrategy                                     │
│  └── HybridRankingStrategy                                       │
│                                                                  │
│  JudgeInvitationService (審査員招待・メール送信)                 │
│  ResultsAnnouncementService (結果発表処理)                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                           Models                                 │
├─────────────────────────────────────────────────────────────────┤
│  Contest (拡張)                                                  │
│  ├── judging_method: enum (judge_only, vote_only, hybrid)        │
│  ├── judge_weight: integer (ハイブリッド時の審査員配分 %)        │
│  ├── prize_count: integer (入賞者数)                             │
│  └── show_detailed_scores: boolean (詳細スコア公開)              │
│                                                                  │
│  ContestRanking (新規)                                           │
│  ├── entry_id, rank, total_score                                 │
│  ├── judge_score, vote_score                                     │
│  └── calculated_at                                               │
│                                                                  │
│  JudgeInvitation (新規)                                          │
│  ├── contest_id, email, token                                    │
│  ├── status: enum (pending, accepted, declined)                  │
│  └── invited_at, responded_at                                    │
│                                                                  │
│  ContestJudge (既存)                                             │
│  JudgeEvaluation (既存)                                          │
│  EvaluationCriterion (既存)                                      │
│  Vote (既存)                                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Database Design

### Contestsテーブル拡張

```ruby
# Migration: add_judging_settings_to_contests
add_column :contests, :judging_method, :integer, default: 0, null: false
# 0: judge_only, 1: vote_only, 2: hybrid
add_column :contests, :judge_weight, :integer, default: 70
# ハイブリッド時の審査員スコア配分(%)、投票は100-judge_weight
add_column :contests, :prize_count, :integer, default: 3
add_column :contests, :show_detailed_scores, :boolean, default: false
```

### ContestRankingsテーブル（新規）

```ruby
# Migration: create_contest_rankings
create_table :contest_rankings do |t|
  t.references :contest, null: false, foreign_key: true
  t.references :entry, null: false, foreign_key: true
  t.integer :rank, null: false
  t.decimal :total_score, precision: 10, scale: 4, null: false
  t.decimal :judge_score, precision: 10, scale: 4
  t.decimal :vote_score, precision: 10, scale: 4
  t.integer :vote_count, default: 0
  t.datetime :calculated_at, null: false
  t.timestamps

  t.index [:contest_id, :rank], unique: true
  t.index [:contest_id, :entry_id], unique: true
end
```

### JudgeInvitationsテーブル（新規）

```ruby
# Migration: create_judge_invitations
create_table :judge_invitations do |t|
  t.references :contest, null: false, foreign_key: true
  t.string :email, null: false
  t.string :token, null: false
  t.integer :status, default: 0, null: false
  # 0: pending, 1: accepted, 2: declined
  t.datetime :invited_at, null: false
  t.datetime :responded_at
  t.references :invited_by, foreign_key: { to_table: :users }
  t.references :user, foreign_key: true  # 承諾後に紐付け
  t.timestamps

  t.index [:contest_id, :email], unique: true
  t.index :token, unique: true
end
```

## API Design

### 審査設定API

```
# 審査設定取得・更新
GET/PATCH /organizers/contests/:contest_id/judging_settings
  Response: { judging_method, judge_weight, prize_count, show_detailed_scores, evaluation_criteria }

# 評価基準（既存拡張）
GET/POST   /organizers/contests/:contest_id/evaluation_criteria
DELETE     /organizers/contests/:contest_id/evaluation_criteria/:id
```

### 審査員管理API

```
# 審査員一覧（既存）
GET    /organizers/contests/:contest_id/judges
POST   /organizers/contests/:contest_id/judges          # 直接追加
DELETE /organizers/contests/:contest_id/judges/:id

# 審査員招待（新規）
POST   /organizers/contests/:contest_id/judge_invitations
  Body: { email }
DELETE /organizers/contests/:contest_id/judge_invitations/:id

# 招待への応答（新規）
GET  /judge_invitations/:token           # 招待詳細
POST /judge_invitations/:token/accept    # 承諾
POST /judge_invitations/:token/decline   # 辞退
```

### 結果管理API

```
# ランキングプレビュー（主催者用）
GET  /organizers/contests/:contest_id/results/preview
  Response: { rankings, judge_completion_rate, can_announce }

# ランキング計算実行
POST /organizers/contests/:contest_id/results/calculate

# 結果発表
POST /organizers/contests/:contest_id/results/announce
  Body: { prize_count }

# 結果閲覧（公開）
GET  /contests/:contest_id/results
  Response: { top_entries, all_rankings (if allowed), my_result (if participant) }
```

## UI Components

### 主催者向け

1. **審査設定画面** (`organizers/judging_settings/edit`)
   - 審査方式選択（ラジオボタン）
   - ハイブリッド時の配分スライダー
   - 評価基準設定（名前、説明、最大点数）
   - 入賞者数設定
   - 詳細スコア公開設定

2. **審査員管理画面** (`organizers/contest_judges/index`) - 既存拡張
   - 審査員一覧（採点進捗率表示）
   - メールで招待フォーム
   - 招待中一覧（ステータス表示）

3. **結果発表管理画面** (`organizers/results/preview`)
   - 暫定ランキング表示
   - 審査員採点完了率
   - 発表設定（入賞者数調整）
   - 結果公開ボタン

### 審査員向け

1. **審査ダッシュボード** (`my/judge_assignments/show`) - 既存
   - 担当コンテスト一覧
   - 採点進捗表示

2. **採点画面** (`my/judge_evaluations/show`) - 既存
   - 作品詳細表示
   - 各評価項目のスコア入力
   - コメント入力

### 参加者・一般向け

1. **結果ページ** (`contests/results/show`) - 既存拡張
   - 入賞作品ギャラリー（バッジ付き）
   - 全ランキング表示（設定による）
   - 自分の結果表示（ログイン時）
   - SNSシェアボタン

## Service Design

### RankingCalculator

```ruby
class RankingCalculator
  def initialize(contest)
    @contest = contest
    @strategy = select_strategy
  end

  def calculate
    entries = @contest.entries.includes(:votes, :judge_evaluations)
    rankings = @strategy.calculate(entries)
    save_rankings(rankings)
  end

  private

  def select_strategy
    case @contest.judging_method
    when 'judge_only'
      JudgeOnlyRankingStrategy.new(@contest)
    when 'vote_only'
      VoteOnlyRankingStrategy.new(@contest)
    when 'hybrid'
      HybridRankingStrategy.new(@contest, @contest.judge_weight)
    end
  end
end
```

### HybridRankingStrategy

```ruby
class HybridRankingStrategy
  def initialize(contest, judge_weight)
    @contest = contest
    @judge_weight = judge_weight / 100.0
    @vote_weight = 1 - @judge_weight
  end

  def calculate(entries)
    max_judge_score = calculate_max_judge_score
    max_votes = entries.map { |e| e.votes.count }.max || 1

    entries.map do |entry|
      judge_score = normalize_judge_score(entry, max_judge_score)
      vote_score = normalize_vote_score(entry.votes.count, max_votes)
      total_score = (judge_score * @judge_weight) + (vote_score * @vote_weight)

      {
        entry: entry,
        total_score: total_score,
        judge_score: judge_score,
        vote_score: vote_score,
        vote_count: entry.votes.count
      }
    end.sort_by { |r| [-r[:total_score], -r[:vote_count], r[:entry].created_at] }
       .each_with_index.map { |r, i| r.merge(rank: i + 1) }
  end

  private

  def normalize_judge_score(entry, max_score)
    return 0 if max_score.zero?
    avg = entry.judge_evaluations.average(:score) || 0
    (avg / max_score) * 100
  end

  def normalize_vote_score(votes, max_votes)
    return 0 if max_votes.zero?
    (votes.to_f / max_votes) * 100
  end

  def calculate_max_judge_score
    @contest.evaluation_criteria.sum(:max_score)
  end
end
```

### JudgeInvitationService

```ruby
class JudgeInvitationService
  def invite(contest:, email:, invited_by:)
    invitation = JudgeInvitation.create!(
      contest: contest,
      email: email,
      token: SecureRandom.urlsafe_base64(32),
      invited_by: invited_by,
      invited_at: Time.current
    )

    JudgeInvitationMailer.invite(invitation).deliver_later
    invitation
  end

  def accept(invitation, user)
    ActiveRecord::Base.transaction do
      invitation.update!(
        status: :accepted,
        user: user,
        responded_at: Time.current
      )

      ContestJudge.create!(
        contest: invitation.contest,
        user: user,
        invited_at: invitation.invited_at
      )
    end
  end
end
```

## Error Handling

| シナリオ | 対応 |
|---------|------|
| コンテスト公開後に審査方式変更 | 変更不可（バリデーションエラー） |
| 審査員が全作品未採点で結果発表 | 警告表示、強制発表は可能 |
| 同点発生 | 投票数 → 審査員平均 → 投稿日時の順で決定 |
| 招待メールのトークン期限切れ | 30日で期限切れ、再招待を促す |
| 結果発表後の評価変更 | 不可（既存のバリデーションで対応済み） |

## Security Considerations

1. **アクセス制御**
   - 審査員は担当コンテストの作品のみ閲覧・採点可能（既存で実装済み）
   - 結果発表前のランキングは主催者のみ閲覧可能
   - 招待トークンは一意で推測困難な値を使用

2. **データ保護**
   - 審査スコアは結果発表まで参加者に非公開
   - 審査員名の匿名化オプション（show_judge_names設定）

3. **監査**
   - 結果発表後の変更はAuditLogに記録（既存の仕組みを利用）

## Testing Strategy

1. **モデルテスト**
   - ContestRankingのバリデーション
   - JudgeInvitationのステータス遷移
   - Contestの審査方式設定バリデーション

2. **サービステスト**
   - 各ランキング戦略の計算ロジック
   - 同点時のタイブレーク処理
   - 招待フロー（送信、承諾、辞退）

3. **コントローラーテスト**
   - 権限チェック（主催者のみ設定可能）
   - 結果発表前後のアクセス制御

4. **システムテスト**
   - 審査設定フロー
   - 審査員招待〜採点〜結果発表フロー
   - 結果閲覧・SNSシェア

## Dependencies

- 既存: Devise（認証）、ActionMailer（メール送信）
- 既存: Turbo/Stimulus（リアルタイムUI更新）
- 新規依存なし

## File Structure

```
app/
├── controllers/
│   ├── organizers/
│   │   ├── judging_settings_controller.rb (新規)
│   │   ├── judge_invitations_controller.rb (新規)
│   │   ├── results_controller.rb (新規)
│   │   └── contest_judges_controller.rb (拡張)
│   ├── judge_invitations_controller.rb (新規: 招待応答用)
│   └── contests/
│       └── results_controller.rb (拡張)
├── models/
│   ├── contest.rb (拡張)
│   ├── contest_ranking.rb (新規)
│   └── judge_invitation.rb (新規)
├── services/
│   ├── ranking_calculator.rb (新規)
│   ├── ranking_strategies/ (新規)
│   │   ├── base_strategy.rb
│   │   ├── judge_only_strategy.rb
│   │   ├── vote_only_strategy.rb
│   │   └── hybrid_strategy.rb
│   ├── judge_invitation_service.rb (新規)
│   └── results_announcement_service.rb (新規)
├── mailers/
│   └── judge_invitation_mailer.rb (新規)
└── views/
    ├── organizers/
    │   ├── judging_settings/ (新規)
    │   ├── judge_invitations/ (新規)
    │   ├── results/ (新規)
    │   └── contest_judges/ (拡張)
    ├── judge_invitations/ (新規)
    └── contests/
        └── results/ (拡張)
```
