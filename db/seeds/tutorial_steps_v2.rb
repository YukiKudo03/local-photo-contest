# frozen_string_literal: true

# チュートリアルステップv2シードデータ
# 桜井政博氏の設計哲学に基づく短いチュートリアル

puts "Seeding Tutorial Steps v2..."

# 既存データをクリア
TutorialStep.delete_all

# ========================================
# 参加者オンボーディング（3ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: "participant_onboarding",
    step_id: "tap_entry",
    position: 1,
    title: "作品をタップ",
    description: "気になる写真を選んでみましょう",
    target_selector: '[data-tutorial="gallery-grid"] a:first-child',
    tooltip_position: "bottom",
    action_type: "tap",
    recommended_duration: 5,
    success_feedback: {
      type: "subtle",
      animation: "pop"
    }
  },
  {
    tutorial_type: "participant_onboarding",
    step_id: "vote",
    position: 2,
    title: "ハートをタップ",
    description: "素敵な作品に投票できます",
    target_selector: '[data-tutorial="vote-button"]',
    tooltip_position: "top",
    action_type: "tap",
    recommended_duration: 5,
    success_feedback: {
      type: "celebration",
      message: "初投票！",
      animation: "heart-burst"
    }
  },
  {
    tutorial_type: "participant_onboarding",
    step_id: "complete",
    position: 3,
    title: "準備完了！",
    description: "さあ、楽しみましょう",
    target_selector: nil,
    tooltip_position: "center",
    action_type: "observe",
    recommended_duration: 3,
    success_feedback: {
      type: "completion",
      message: "準備完了！"
    }
  }
])

# ========================================
# 運営者オンボーディング（3ステップ）
# ダッシュボードで完結するシンプルなチュートリアル
# ========================================
TutorialStep.create!([
  {
    tutorial_type: "organizer_onboarding",
    step_id: "welcome",
    position: 1,
    title: "ダッシュボード",
    description: "ここが運営の拠点です",
    target_selector: nil,
    tooltip_position: "center",
    action_type: "observe",
    recommended_duration: 5,
    success_feedback: { type: "subtle" }
  },
  {
    tutorial_type: "organizer_onboarding",
    step_id: "create_contest",
    position: 2,
    title: "コンテスト作成",
    description: "ここから作成できます",
    target_selector: '[data-tutorial="create-contest"]',
    tooltip_position: "bottom",
    action_type: "tap",
    recommended_duration: 5,
    success_feedback: { type: "subtle" }
  },
  {
    tutorial_type: "organizer_onboarding",
    step_id: "stats",
    position: 3,
    title: "統計情報",
    description: "ここで状況を確認",
    target_selector: '[data-tutorial="stats-grid"]',
    tooltip_position: "bottom",
    action_type: "observe",
    recommended_duration: 5,
    success_feedback: {
      type: "completion",
      message: "準備完了！"
    }
  }
])

# ========================================
# 審査員オンボーディング（2ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: "judge_onboarding",
    step_id: "select_entry",
    position: 1,
    title: "作品を選択",
    description: "審査する作品をタップ",
    target_selector: '[data-tutorial="judge-assignments"] a:first-child',
    tooltip_position: "bottom",
    action_type: "tap",
    recommended_duration: 5,
    success_feedback: { type: "subtle" }
  },
  {
    tutorial_type: "judge_onboarding",
    step_id: "score",
    position: 2,
    title: "スライダーで評価",
    description: "直感で評価してください",
    target_selector: '[data-tutorial="score-input"]',
    tooltip_position: "left",
    action_type: "drag",
    recommended_duration: 5,
    success_feedback: {
      type: "completion",
      message: "評価を保存"
    }
  }
])

# ========================================
# 写真投稿チュートリアル（3ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: "photo_submission",
    step_id: "select_photo",
    position: 1,
    title: "写真を選択",
    description: "ドロップまたはタップ",
    target_selector: '[data-tutorial="photo-upload"]',
    tooltip_position: "bottom",
    action_type: "tap",
    recommended_duration: 5,
    success_feedback: { type: "subtle" }
  },
  {
    tutorial_type: "photo_submission",
    step_id: "title",
    position: 2,
    title: "タイトルを入力",
    description: "作品の名前をつけましょう",
    target_selector: '[data-tutorial="entry-title"]',
    tooltip_position: "top",
    action_type: "input",
    recommended_duration: 5,
    success_feedback: { type: "subtle" }
  },
  {
    tutorial_type: "photo_submission",
    step_id: "submit",
    position: 3,
    title: "投稿ボタン",
    description: "これで投稿完了！",
    target_selector: '[data-tutorial="entry-submit"]',
    tooltip_position: "top",
    action_type: "tap",
    recommended_duration: 5,
    success_feedback: {
      type: "celebration",
      message: "投稿完了！",
      animation: "pop"
    }
  }
])

# ========================================
# 管理者オンボーディング（2ステップ）
# ========================================
TutorialStep.create!([
  {
    tutorial_type: "admin_onboarding",
    step_id: "nav_overview",
    position: 1,
    title: "ナビゲーション",
    description: "各メニューで管理できます",
    target_selector: '[data-tutorial="admin-nav"]',
    tooltip_position: "bottom",
    action_type: "observe",
    recommended_duration: 5,
    success_feedback: { type: "subtle" }
  },
  {
    tutorial_type: "admin_onboarding",
    step_id: "stats",
    position: 2,
    title: "ダッシュボード",
    description: "ここで状況を把握",
    target_selector: '[data-tutorial="admin-stats"]',
    tooltip_position: "bottom",
    action_type: "observe",
    recommended_duration: 5,
    success_feedback: {
      type: "completion",
      message: "準備完了！"
    }
  }
])

puts "Tutorial steps v2 created: #{TutorialStep.count} steps"
