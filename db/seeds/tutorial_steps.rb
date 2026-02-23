# チュートリアルステップのシードデータ

puts "Creating tutorial steps..."

# 既存のデータをクリア
TutorialStep.destroy_all

# ========================================
# 参加者オンボーディング
# ========================================
participant_onboarding_steps = [
  {
    step_id: "welcome",
    position: 1,
    title: "Local Photo Contestへようこそ！",
    description: "地域の魅力を写真で発信するプラットフォームです。写真の投稿や投票を通じて、地域の魅力を共有しましょう。",
    target_selector: nil,
    target_path: nil,
    tooltip_position: "center"
  },
  {
    step_id: "contests_list",
    position: 2,
    title: "コンテスト一覧",
    description: "開催中のコンテストがここに表示されます。興味のあるコンテストをクリックして詳細を確認しましょう。",
    target_selector: "[data-tutorial='contests-list']",
    target_path: "/contests",
    tooltip_position: "bottom"
  },
  {
    step_id: "gallery",
    position: 3,
    title: "ギャラリー",
    description: "投稿された写真をギャラリーで閲覧できます。地図表示で撮影場所も確認できます。",
    target_selector: "[data-tutorial='gallery-link']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "submit_photo",
    position: 4,
    title: "写真を投稿",
    description: "コンテストに参加するには、写真を投稿しましょう。撮影場所の情報も一緒に登録できます。",
    target_selector: "[data-tutorial='submit-button']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "my_page",
    position: 5,
    title: "マイページ",
    description: "投稿した写真や投票履歴はマイページで確認できます。通知もここで確認できます。",
    target_selector: "[data-tutorial='my-page-link']",
    target_path: nil,
    tooltip_position: "bottom"
  }
]

participant_onboarding_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "participant_onboarding"))
end

# ========================================
# 運営者オンボーディング
# ========================================
organizer_onboarding_steps = [
  {
    step_id: "welcome",
    position: 1,
    title: "運営者ダッシュボードへようこそ！",
    description: "ここからフォトコンテストの作成・運営ができます。まずは基本的な機能をご案内します。",
    target_selector: nil,
    target_path: "/organizers/dashboard",
    tooltip_position: "center"
  },
  {
    step_id: "create_contest",
    position: 2,
    title: "コンテストを作成",
    description: "「新規コンテスト」ボタンからコンテストを作成できます。テーマ、期間、賞品などを設定しましょう。",
    target_selector: "[data-tutorial='new-contest-button']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "area_management",
    position: 3,
    title: "エリア管理",
    description: "コンテストの対象エリアを設定できます。撮影スポットの登録もここから行います。",
    target_selector: "[data-tutorial='areas-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "spot_management",
    position: 4,
    title: "スポット管理",
    description: "撮影スポットを登録すると、参加者が位置情報を簡単に選択できます。",
    target_selector: "[data-tutorial='spots-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "judge_invitation",
    position: 5,
    title: "審査員招待",
    description: "審査員を招待してプロフェッショナルな評価を追加できます。メールで招待状を送信します。",
    target_selector: "[data-tutorial='judges-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "moderation",
    position: 6,
    title: "モデレーション",
    description: "投稿された写真を確認し、承認・却下できます。不適切なコンテンツを管理しましょう。",
    target_selector: "[data-tutorial='moderation-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "statistics",
    position: 7,
    title: "統計・分析",
    description: "応募数の推移やエリア別の分布を確認できます。コンテストの効果を分析しましょう。",
    target_selector: "[data-tutorial='statistics-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "results",
    position: 8,
    title: "結果発表",
    description: "コンテスト終了後、ランキングを確認して結果を発表できます。参加者に通知が送信されます。",
    target_selector: "[data-tutorial='results-link']",
    target_path: nil,
    tooltip_position: "right"
  }
]

organizer_onboarding_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "organizer_onboarding"))
end

# ========================================
# 管理者オンボーディング
# ========================================
admin_onboarding_steps = [
  {
    step_id: "welcome",
    position: 1,
    title: "管理者ダッシュボードへようこそ！",
    description: "システム全体の管理機能にアクセスできます。ユーザー管理、コンテスト管理、監査ログなどを確認できます。",
    target_selector: nil,
    target_path: "/admin/dashboard",
    tooltip_position: "center"
  },
  {
    step_id: "user_management",
    position: 2,
    title: "ユーザー管理",
    description: "登録ユーザーの一覧を確認し、ロールの変更やアカウントの停止を行えます。",
    target_selector: "[data-tutorial='admin-users-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "contest_management",
    position: 3,
    title: "コンテスト管理",
    description: "すべてのコンテストを管理できます。問題のあるコンテストは強制終了できます。",
    target_selector: "[data-tutorial='admin-contests-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "category_management",
    position: 4,
    title: "カテゴリ管理",
    description: "コンテストのカテゴリを追加・編集できます。",
    target_selector: "[data-tutorial='admin-categories-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "audit_logs",
    position: 5,
    title: "監査ログ",
    description: "システム上の重要な操作を記録した監査ログを確認できます。セキュリティ監視に役立ちます。",
    target_selector: "[data-tutorial='admin-audit-logs-link']",
    target_path: nil,
    tooltip_position: "right"
  },
  {
    step_id: "complete",
    position: 6,
    title: "準備完了！",
    description: "管理者機能の概要を確認しました。いつでもヘルプボタンからチュートリアルを再開できます。",
    target_selector: nil,
    target_path: nil,
    tooltip_position: "center"
  }
]

admin_onboarding_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "admin_onboarding"))
end

# ========================================
# 審査員オンボーディング
# ========================================
judge_onboarding_steps = [
  {
    step_id: "welcome",
    position: 1,
    title: "審査員としてご参加いただきありがとうございます！",
    description: "このチュートリアルでは、審査の方法をご案内します。",
    target_selector: nil,
    target_path: nil,
    tooltip_position: "center"
  },
  {
    step_id: "assignments",
    position: 2,
    title: "審査対象の確認",
    description: "担当するコンテストの応募作品がここに表示されます。",
    target_selector: "[data-tutorial='judge-assignments']",
    target_path: "/my/judge_assignments",
    tooltip_position: "bottom"
  },
  {
    step_id: "criteria",
    position: 3,
    title: "評価基準",
    description: "コンテストごとに設定された評価基準を確認してください。基準に沿って公平に評価しましょう。",
    target_selector: "[data-tutorial='evaluation-criteria']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "scoring",
    position: 4,
    title: "スコア入力",
    description: "各作品に対してスコアを入力します。複数の評価基準がある場合は、それぞれにスコアをつけてください。",
    target_selector: "[data-tutorial='score-input']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "comments",
    position: 5,
    title: "コメント",
    description: "作品へのコメントを残すことができます。参加者へのフィードバックとして活用されます。",
    target_selector: "[data-tutorial='judge-comment']",
    target_path: nil,
    tooltip_position: "bottom"
  }
]

judge_onboarding_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "judge_onboarding"))
end

# ========================================
# コンテスト作成チュートリアル
# ========================================
contest_creation_steps = [
  {
    step_id: "basic_info",
    position: 1,
    title: "基本情報の入力",
    description: "コンテストのタイトル、説明、テーマを入力します。参加者に魅力が伝わるよう工夫しましょう。",
    target_selector: "[data-tutorial='contest-title']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "period_setting",
    position: 2,
    title: "期間設定",
    description: "応募期間と審査期間を設定します。十分な応募期間を確保しましょう。",
    target_selector: "[data-tutorial='contest-period']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "category",
    position: 3,
    title: "カテゴリ選択",
    description: "コンテストのカテゴリを選択します。適切なカテゴリを選ぶと参加者に見つけてもらいやすくなります。",
    target_selector: "[data-tutorial='contest-category']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "area",
    position: 4,
    title: "対象エリア",
    description: "コンテストの対象エリアを選択します。事前にエリアを作成しておく必要があります。",
    target_selector: "[data-tutorial='contest-area']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "save",
    position: 5,
    title: "保存と公開",
    description: "入力が完了したら保存します。下書き状態で保存後、準備ができたら公開できます。",
    target_selector: "[data-tutorial='contest-submit']",
    target_path: nil,
    tooltip_position: "top"
  }
]

contest_creation_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "contest_creation"))
end

# ========================================
# エリア管理チュートリアル
# ========================================
area_management_steps = [
  {
    step_id: "overview",
    position: 1,
    title: "エリア管理について",
    description: "エリアを作成して、コンテストの撮影対象エリアを設定できます。エリア内にスポットを登録することもできます。",
    target_selector: nil,
    target_path: "/organizers/areas",
    tooltip_position: "center"
  },
  {
    step_id: "create_area",
    position: 2,
    title: "エリアを作成",
    description: "「新規作成」ボタンからエリアを作成できます。エリア名と位置情報を設定しましょう。",
    target_selector: "[data-tutorial='new-area-button']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "area_list",
    position: 3,
    title: "エリア一覧",
    description: "作成したエリアはここに表示されます。クリックして詳細を確認・編集できます。",
    target_selector: "[data-tutorial='area-list']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "spots",
    position: 4,
    title: "スポット管理",
    description: "エリア内に撮影スポットを登録できます。参加者がスポットを選択して写真を投稿できるようになります。",
    target_selector: "[data-tutorial='spots-link']",
    target_path: nil,
    tooltip_position: "right"
  }
]

area_management_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "area_management"))
end

# ========================================
# 写真投稿チュートリアル
# ========================================
photo_submission_steps = [
  {
    step_id: "select_image",
    position: 1,
    title: "写真を選択",
    description: "投稿する写真を選択します。JPEG、PNG、WebP形式に対応しています。",
    target_selector: "[data-tutorial='photo-upload']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "title_description",
    position: 2,
    title: "タイトルと説明",
    description: "写真のタイトルと説明を入力します。撮影時のエピソードなどを添えると魅力的です。",
    target_selector: "[data-tutorial='entry-title']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "select_spot",
    position: 3,
    title: "撮影スポットを選択",
    description: "撮影場所を選択します。リストから選ぶか、新しいスポットを登録できます。",
    target_selector: "[data-tutorial='spot-select']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "submit",
    position: 4,
    title: "投稿",
    description: "内容を確認して投稿しましょう。投稿後も編集期間内であれば修正できます。",
    target_selector: "[data-tutorial='entry-submit']",
    target_path: nil,
    tooltip_position: "top"
  }
]

photo_submission_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "photo_submission"))
end

# ========================================
# 投票チュートリアル
# ========================================
voting_steps = [
  {
    step_id: "browse",
    position: 1,
    title: "作品を閲覧",
    description: "投稿された作品をギャラリーで閲覧できます。クリックすると詳細が表示されます。",
    target_selector: "[data-tutorial='gallery-grid']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "vote",
    position: 2,
    title: "投票する",
    description: "気に入った作品にハートボタンで投票できます。1つの作品に1票投票できます。",
    target_selector: "[data-tutorial='vote-button']",
    target_path: nil,
    tooltip_position: "bottom"
  },
  {
    step_id: "check_votes",
    position: 3,
    title: "投票履歴",
    description: "マイページで投票した作品を確認できます。",
    target_selector: "[data-tutorial='my-votes-link']",
    target_path: nil,
    tooltip_position: "bottom"
  }
]

voting_steps.each do |step|
  TutorialStep.create!(step.merge(tutorial_type: "voting"))
end

puts "Created #{TutorialStep.count} tutorial steps."
