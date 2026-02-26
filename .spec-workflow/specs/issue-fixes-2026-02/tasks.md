# Issue対応タスクリスト（TDD方式）

## TDDサイクル凡例
- 🔴 **Red**: 失敗するテストを書く
- 🟢 **Green**: テストを通す最小限の実装
- 🔵 **Refactor**: コードを整理（テスト維持）

---

## Phase 1: クリティカル

### Issue #16: N+1クエリの修正（GalleryController#map_data）

#### 1.1 N+1クエリ検出テストの追加
- [ ] 🔴 1.1.1 `spec/requests/gallery_spec.rb` にN+1検出テストを作成
  ```ruby
  describe "GET /gallery/map_data" do
    it "does not cause N+1 queries when loading votes" do
      entries = create_list(:entry, 5, :with_votes)
      expect {
        get gallery_map_data_path(format: :json)
      }.to make_database_queries(count: ..10)  # 上限設定
    end
  end
  ```
- [ ] 🔴 1.1.2 テスト実行して失敗を確認（現状のN+1を検出）

#### 1.2 プリロードの実装
- [ ] 🟢 1.2.1 `gallery_controller.rb` で `includes(:votes)` を追加
- [ ] 🟢 1.2.2 `votes.count` を `votes.size` に変更
- [ ] 🟢 1.2.3 テストが通ることを確認

#### 1.3 リファクタリング
- [ ] 🔵 1.3.1 マップデータ構築ロジックをプライベートメソッドに抽出
- [ ] 🔵 1.3.2 bullet gem を追加してCI連携
- [ ] 1.3.3 Issue #16 をクローズ

---

### Issue #17: 管理ダッシュボードのクエリ最適化

#### 1.4 DashboardStatsServiceのテスト作成
- [ ] 🔴 1.4.1 `spec/services/admin/dashboard_stats_service_spec.rb` を作成
  ```ruby
  RSpec.describe Admin::DashboardStatsService do
    describe "#all_stats" do
      it "returns total user count" do
        create_list(:user, 3)
        expect(service.all_stats[:total_users]).to eq(3)
      end
    end
  end
  ```
- [ ] 🔴 1.4.2 各統計項目のテストを追加（contests, entries, votes）
- [ ] 🔴 1.4.3 今日の統計テストを追加

#### 1.5 DashboardStatsServiceの実装
- [ ] 🟢 1.5.1 `app/services/admin/dashboard_stats_service.rb` を作成
- [ ] 🟢 1.5.2 `all_stats` メソッドで全統計を1回のクエリで取得
- [ ] 🟢 1.5.3 コントローラーでサービスを使用

#### 1.6 キャッシュのテスト作成
- [ ] 🔴 1.6.1 キャッシュ動作のテストを追加
  ```ruby
  it "caches results for 5 minutes" do
    service.all_stats
    create(:user)  # 新規ユーザー追加
    expect(service.all_stats[:total_users]).to eq(previous_count)  # キャッシュから
  end
  ```
- [ ] 🔴 1.6.2 キャッシュ無効化のテストを追加

#### 1.7 キャッシュの実装
- [ ] 🟢 1.7.1 `Rails.cache.fetch` でキャッシュ実装
- [ ] 🟢 1.7.2 キャッシュキーとTTL設定

#### 1.8 リファクタリング
- [ ] 🔵 1.8.1 コントローラーをシンプルに整理
- [ ] 🔵 1.8.2 ビューでの表示を最適化
- [ ] 1.8.3 Issue #17 をクローズ

---

### Issue #18: 投票のレースコンディション対策

#### 1.9 DBユニーク制約のテスト
- [ ] 🔴 1.9.1 `spec/models/vote_spec.rb` にDB制約テストを追加
  ```ruby
  describe "database constraints" do
    it "enforces uniqueness at database level" do
      vote = create(:vote)
      duplicate = build(:vote, user: vote.user, entry: vote.entry)
      duplicate.save(validate: false)  # バリデーションスキップ
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
  ```

#### 1.10 マイグレーションの作成
- [ ] 🟢 1.10.1 ユニークインデックスのマイグレーション作成
  ```ruby
  add_index :votes, [:user_id, :entry_id], unique: true,
            name: 'index_votes_on_user_and_entry_unique',
            if_not_exists: true
  ```
- [ ] 🟢 1.10.2 マイグレーション実行
- [ ] 🟢 1.10.3 テストが通ることを確認

#### 1.11 コントローラーの例外ハンドリングテスト
- [ ] 🔴 1.11.1 `spec/requests/votes_spec.rb` に競合テストを追加
  ```ruby
  describe "POST /entries/:entry_id/votes" do
    it "handles duplicate vote gracefully" do
      create(:vote, user: user, entry: entry)
      post entry_votes_path(entry), headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
  ```

#### 1.12 例外ハンドリングの実装
- [ ] 🟢 1.12.1 `VotesController` で `RecordNotUnique` をrescue
- [ ] 🟢 1.12.2 適切なエラーメッセージを返す

#### 1.13 リファクタリング
- [ ] 🔵 1.13.1 投票ロジックをサービスに抽出（任意）
- [ ] 1.13.2 Issue #18 をクローズ

---

## Phase 2: 高優先度

### Issue #19: 観光連携機能の完成

#### 2.1 スポット統合機能

##### 2.1.1 スポット統合サービスのテスト
- [x] 🔴 2.1.1.1 `spec/services/spot_merge_service_spec.rb` を作成
- [x] 🔴 2.1.1.2 関連エントリーの移行テスト
- [x] 🔴 2.1.1.3 投票の統合テスト

##### 2.1.2 スポット統合サービスの実装
- [x] 🟢 2.1.2.1 `SpotMergeService` を作成
- [x] 🟢 2.1.2.2 マイグレーション: `merged_into_id` カラム追加
- [x] 🟢 2.1.2.3 関連データの移行ロジック実装

##### 2.1.3 スポット統合UIのテスト
- [x] 🔴 2.1.3.1 `spec/system/organizers/spot_management_spec.rb` を更新
- [x] 🟢 2.1.3.2 統合UIの実装（コントローラー・ビュー）

#### 2.2 スポット認定ワークフロー

##### 2.2.1 認定ステータス管理のテスト
- [x] 🔴 2.2.1.1 認定ステータス変更のテスト（既存）
- [x] 🔴 2.2.1.2 認定基準チェックのテスト（既存）
- [x] 🟢 2.2.1.3 認定サービスの実装（既存: DiscoverySpotService）

##### 2.2.2 認定UIのテスト
- [x] 🔴 2.2.2.1 システムテスト作成（既存）
- [x] 🟢 2.2.2.2 認定ダッシュボードUI実装（既存）

#### 2.3 チャレンジ結果分析

##### 2.3.1 分析サービスのテスト
- [x] 🔴 2.3.1.1 `spec/services/challenge_analytics_service_spec.rb` 作成
- [x] 🟢 2.3.1.2 ChallengeAnalyticsService実装

##### 2.3.2 分析ダッシュボードのテスト
- [x] 🔴 2.3.2.1 システムテスト作成
- [x] 🟢 2.3.2.2 ダッシュボードUI実装
- [x] 🔵 2.3.2.3 リファクタリング（data-testid属性追加）
- [x] 2.3.3 Issue #19 をクローズ

---

### Issue #20: システムテストの拡充

#### 2.4 コンテストライフサイクルE2Eテスト
- [x] 🔴 2.4.1 `spec/system/contest_lifecycle_spec.rb` 作成（既存: 13テスト）
- [x] 🟢 2.4.2 テストが通るまで既存機能を確認・修正

#### 2.5 審査員評価フローE2Eテスト
- [x] 🔴 2.5.1 `spec/system/judge_evaluation_spec.rb` 作成（既存: 13テスト）
- [x] 🟢 2.5.2 テストが通ることを確認

#### 2.6 スポットディスカバリーE2Eテスト
- [x] 🔴 2.6.1 `spec/system/spot_discovery_flow_spec.rb` 作成
- [x] 🟢 2.6.2 テストが通ることを確認
- [x] 2.6.3 Issue #20 をクローズ

---

### Issue #21: キャッシュ戦略の導入

#### 2.7 Redisセットアップ
- [ ] 2.7.1 Gemfileに `redis` gem追加
- [ ] 2.7.2 `config/environments/*.rb` でキャッシュストア設定

#### 2.8 コンテスト統計キャッシュ
- [ ] 🔴 2.8.1 `spec/services/statistics_service_spec.rb` にキャッシュテスト追加
- [ ] 🟢 2.8.2 キャッシュ実装
- [ ] 🔴 2.8.3 無効化テスト追加
- [ ] 🟢 2.8.4 Entry作成時のキャッシュ無効化実装

#### 2.9 ギャラリーフラグメントキャッシュ
- [ ] 🔴 2.9.1 キャッシュヒット確認テスト
- [ ] 🟢 2.9.2 ビューにフラグメントキャッシュ追加
- [ ] 🔵 2.9.3 キャッシュキー設計の最適化
- [ ] 2.9.4 Issue #21 をクローズ

---

## Phase 3: 中優先度

### Issue #22: 統計ダッシュボード機能拡張

#### 3.1 CSVエクスポート
- [ ] 🔴 3.1.1 エクスポートサービスのテスト作成
- [ ] 🟢 3.1.2 CSVエクスポート実装
- [ ] 🔴 3.1.3 コントローラーテスト作成
- [ ] 🟢 3.1.4 エンドポイント実装

#### 3.2 日付範囲フィルター
- [ ] 🔴 3.2.1 日付範囲フィルターのテスト
- [ ] 🟢 3.2.2 フィルター機能実装
- [ ] 3.2.3 Issue #22 をクローズ

---

### Issue #23: APM・エラートラッキング導入

#### 3.3 Sentry導入
- [ ] 3.3.1 `sentry-ruby` gem追加
- [ ] 3.3.2 初期設定
- [ ] 🔴 3.3.3 エラー通知テスト
- [ ] 🟢 3.3.4 設定調整
- [ ] 3.3.5 Issue #23 をクローズ

---

### Issue #24: UI/UX改善

#### 3.4 遅延読み込み（Lazy Loading）
- [ ] 🔴 3.4.1 画像遅延読み込みのシステムテスト
- [ ] 🟢 3.4.2 `loading="lazy"` 属性追加
- [ ] 🟢 3.4.3 Intersection Observer実装

#### 3.5 無限スクロール
- [ ] 🔴 3.5.1 無限スクロールのシステムテスト
- [ ] 🟢 3.5.2 Stimulusコントローラー作成
- [ ] 🟢 3.5.3 Turbo Framesでページネーション
- [ ] 3.5.4 Issue #24 をクローズ

---

### Issue #25: インデックス追加とスキーマ改善

#### 3.6 複合インデックス追加
- [ ] 🔴 3.6.1 クエリパフォーマンステスト作成
- [ ] 🟢 3.6.2 マイグレーション作成・実行
  ```ruby
  add_index :entries, [:contest_id, :moderation_status]
  add_index :evaluations, [:judge_id, :entry_id]
  ```

#### 3.7 バリデーション強化
- [ ] 🔴 3.7.1 文字数制限テスト追加
- [ ] 🟢 3.7.2 バリデーション実装
- [ ] 3.7.3 Issue #25 をクローズ

---

### Issue #26: 審査・ランキング機能完成

#### 3.8 ランキングプレビュー
- [ ] 🔴 3.8.1 プレビュー機能のテスト
- [ ] 🟢 3.8.2 プレビューエンドポイント実装
- [ ] 🟢 3.8.3 プレビューUI実装

#### 3.9 進捗トラッキング
- [ ] 🔴 3.9.1 進捗計算のテスト
- [ ] 🟢 3.9.2 進捗表示UI実装
- [ ] 3.9.3 Issue #26 をクローズ

---

### Issue #29: スポット投票のレート制限

#### 3.10 Rack::Attack導入
- [ ] 3.10.1 `rack-attack` gem追加
- [ ] 🔴 3.10.2 レート制限テスト作成
  ```ruby
  describe "rate limiting" do
    it "blocks excessive requests" do
      11.times { post spot_votes_path(spot) }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
  ```
- [ ] 🟢 3.10.3 Rack::Attack設定実装
- [ ] 3.10.4 Issue #29 をクローズ

---

## Phase 4: 低優先度

### Issue #27: コード品質改善

#### 4.1 サービス分割
- [ ] 🔴 4.1.1 既存テストが通ることを確認
- [ ] 🔵 4.1.2 DiscoverySpotServiceのリファクタリング
- [ ] 🔵 4.1.3 RankingStrategiesのディレクトリ移動
- [ ] 4.1.4 Issue #27 をクローズ

---

### Issue #28: APIドキュメント作成

#### 4.2 OpenAPI仕様書
- [ ] 4.2.1 `rswag` gem追加
- [ ] 4.2.2 既存エンドポイントの仕様記述
- [ ] 4.2.3 Swagger UI設定
- [ ] 4.2.4 Issue #28 をクローズ

---

## 進捗トラッキング

### Phase 1 サマリー
| Issue | タスク数 | 完了 | 状態 |
|-------|---------|------|------|
| #16 N+1修正 | 9 | 0 | 未着手 |
| #17 ダッシュボード最適化 | 12 | 0 | 未着手 |
| #18 レースコンディション | 10 | 0 | 未着手 |

### Phase 2 サマリー
| Issue | タスク数 | 完了 | 状態 |
|-------|---------|------|------|
| #19 観光連携 | 16 | 0 | 未着手 |
| #20 システムテスト | 7 | 0 | 未着手 |
| #21 キャッシュ戦略 | 11 | 0 | 未着手 |

### Phase 3 サマリー
| Issue | タスク数 | 完了 | 状態 |
|-------|---------|------|------|
| #22 統計拡張 | 5 | 0 | 未着手 |
| #23 APM導入 | 5 | 0 | 未着手 |
| #24 UI/UX改善 | 8 | 0 | 未着手 |
| #25 インデックス | 5 | 0 | 未着手 |
| #26 審査機能 | 6 | 0 | 未着手 |
| #29 レート制限 | 4 | 0 | 未着手 |

### Phase 4 サマリー
| Issue | タスク数 | 完了 | 状態 |
|-------|---------|------|------|
| #27 コード品質 | 4 | 0 | 未着手 |
| #28 APIドキュメント | 4 | 0 | 未着手 |

---

## 注意事項

### TDD実践のポイント
1. **テストは1つずつ**: 複数のテストを一度に書かない
2. **最小限の実装**: テストを通す最小のコードを書く
3. **リファクタリングは別ステップ**: Green後に行う
4. **コミット頻度**: Red→Green→Refactorごとにコミット推奨

### マイグレーション注意
- #18, #25 のマイグレーションは本番影響あり
- 実行前にバックアップ確認
- ダウンタイムなしで実行可能か検証

### 依存関係
- #21（キャッシュ）は #17 の前提となる可能性あり
- #25（インデックス）は #18 の一部を含む
