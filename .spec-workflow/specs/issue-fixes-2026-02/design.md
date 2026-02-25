# Issue対応設計書

## 概要

GitHub Issues #16-#29 の対応設計書です。t-wada式テスト駆動開発（TDD）の手法を採用し、Red-Green-Refactorサイクルで実装を進めます。

---

## TDD原則（t-wada式）

### 基本サイクル
1. **Red**: 失敗するテストを書く（最小限の1つ）
2. **Green**: テストを通す最小限のコードを書く
3. **Refactor**: コードを整理する（テストは通ったまま）

### 実践ルール
- テストは1つずつ書く
- 仮実装 → 三角測量 → 明白な実装
- テストとコードの間を小さく往復
- 不安をテストに変える

---

## Phase 1: クリティカル（#16, #17, #18）

### Issue #16: N+1クエリの修正（GalleryController#map_data）

#### 現状分析
```ruby
# app/controllers/gallery_controller.rb:115
entries.each { |entry| entry.votes.count }  # N+1発生
```

#### 設計方針
1. `includes(:votes)` でプリロード
2. `size` メソッドでプリロード済みデータを使用
3. bullet gem でN+1検出を自動化

#### テスト設計
```ruby
# spec/controllers/gallery_controller_spec.rb
describe "GET #map_data" do
  it "does not cause N+1 queries for votes" do
    # Given: 複数のエントリーと投票
    # When: map_dataを呼び出す
    # Then: クエリ数が一定（エントリー数に依存しない）
  end
end
```

---

### Issue #17: 管理ダッシュボードのクエリ最適化

#### 現状分析
```ruby
# app/controllers/admin/dashboard_controller.rb:7-31
User.count      # 個別クエリ
Contest.count   # 個別クエリ
Entry.count     # 個別クエリ
Vote.count      # 個別クエリ
```

#### 設計方針
1. DashboardStatsService を作成
2. Redisキャッシュ（5分）を導入
3. カウンターキャッシュの検討

#### アーキテクチャ
```
┌─────────────────────┐
│ DashboardController │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ DashboardStatsService│
└─────────┬───────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
┌───────┐  ┌────────┐
│ Cache │  │Database│
└───────┘  └────────┘
```

#### テスト設計
```ruby
# spec/services/dashboard_stats_service_spec.rb
describe DashboardStatsService do
  describe "#all_stats" do
    it "returns user count" do }
    it "returns contest count" do }
    it "caches results for 5 minutes" do }
    it "invalidates cache on demand" do }
  end
end
```

---

### Issue #18: 投票のレースコンディション対策

#### 現状分析
```ruby
# app/models/vote.rb:9
validates :user_id, uniqueness: { scope: :entry_id }  # アプリレベルのみ
```

#### 設計方針
1. DBレベルのユニーク制約追加
2. `find_or_create_by!` + トランザクション
3. 例外ハンドリング

#### マイグレーション設計
```ruby
# db/migrate/xxx_add_unique_index_to_votes.rb
add_index :votes, [:user_id, :entry_id], unique: true,
          name: 'index_votes_on_user_and_entry_unique'
```

#### テスト設計
```ruby
# spec/models/vote_spec.rb
describe "uniqueness constraint" do
  it "prevents duplicate votes at database level" do
    # Given: 既存の投票
    # When: 同じユーザー・エントリーで投票を作成
    # Then: ActiveRecord::RecordNotUnique が発生
  end
end

# spec/requests/votes_spec.rb
describe "concurrent voting" do
  it "handles race condition gracefully" do
    # Given: 2つの同時リクエスト
    # When: 両方が同時に投票を試みる
    # Then: 1つだけ成功し、もう1つは適切にハンドリング
  end
end
```

---

## Phase 2: 高優先度（#19, #20, #21）

### Issue #19: 観光連携機能の完成

#### 機能分解
1. スポット統合機能
2. スポット認定ワークフロー
3. チャレンジ結果分析

#### アーキテクチャ
```
┌──────────────────┐
│ TourismController │
└────────┬─────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌─────────────┐
│SpotMerge│ │Certification│
│Service  │ │Service      │
└────────┘ └─────────────┘
```

---

### Issue #20: システムテストの拡充

#### テスト対象フロー
1. コンテスト作成 → 公開 → 応募 → 審査 → 結果発表
2. 審査員評価フロー
3. スポットディスカバリーフロー

---

### Issue #21: キャッシュ戦略の導入

#### キャッシュ設計
| キー | TTL | 無効化 |
|------|-----|--------|
| `contest_stats:#{id}` | 5min | Entry作成時 |
| `user_vote_count:#{id}` | 1min | Vote作成/削除時 |
| `spot_ranking:#{contest_id}` | 5min | SpotVote変更時 |
| `admin_dashboard` | 5min | - |

---

## Phase 3: 中優先度（#22-#26, #29）

### Issue #22: 統計ダッシュボード機能拡張
- CSV/PDF/Excelエクスポート
- カスタム日付範囲
- 前回コンテスト比較

### Issue #23: APM・エラートラッキング
- Sentry導入
- Scout APM導入

### Issue #24: UI/UX改善
- 遅延読み込み
- 無限スクロール
- トースト通知

### Issue #25: インデックス追加
- 複合インデックス追加
- バリデーション強化

### Issue #26: 審査・ランキング機能完成
- ランキングプレビュー
- 進捗トラッキング

### Issue #29: レート制限
- Rack::Attack導入

---

## Phase 4: 低優先度（#27, #28）

### Issue #27: コード品質改善
- サービス分割
- ViewComponent導入

### Issue #28: APIドキュメント
- OpenAPI仕様書作成

---

## 依存関係

```
#18 投票レースコンディション
  └── #25 インデックス追加（部分的に含む）

#17 ダッシュボード最適化
  └── #21 キャッシュ戦略（前提）

#19 観光連携
  └── #20 システムテスト（テスト追加）
```

---

## リスク・注意点

1. **マイグレーション**: #18, #25 は本番DBへの影響あり
2. **キャッシュ**: Redis依存を追加（#21）
3. **外部サービス**: Sentry/Scout等の契約が必要（#23）

---

## 見積もりサマリー

| Phase | Issue数 | 合計工数 |
|-------|---------|----------|
| Phase 1（クリティカル） | 3 | 2-3日 |
| Phase 2（高優先度） | 3 | 2-3週間 |
| Phase 3（中優先度） | 6 | 2-3週間 |
| Phase 4（低優先度） | 2 | 3-5日 |

**総見積もり**: 5-7週間
