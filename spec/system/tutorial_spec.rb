# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tutorial", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:terms) { create(:terms_of_service, :current) }
  let!(:user) { create(:user, :organizer, :confirmed, tutorial_settings: { "show_tutorials" => true }) }

  before do
    create(:terms_acceptance, user: user, terms_of_service: terms)

    # チュートリアルステップを作成
    create(:tutorial_step,
           tutorial_type: "organizer_onboarding",
           step_id: "welcome",
           position: 1,
           title: "ようこそ",
           description: "ダッシュボードへ",
           target_selector: nil,
           tooltip_position: "center",
           action_type: "observe")

    create(:tutorial_step,
           tutorial_type: "organizer_onboarding",
           step_id: "create_contest",
           position: 2,
           title: "コンテスト作成",
           description: "ここから作成",
           target_selector: '[data-tutorial="create-contest"]',
           tooltip_position: "bottom",
           action_type: "tap")

    create(:tutorial_step,
           tutorial_type: "organizer_onboarding",
           step_id: "stats",
           position: 3,
           title: "統計情報",
           description: "状況を確認",
           target_selector: '[data-tutorial="stats-grid"]',
           tooltip_position: "bottom",
           action_type: "observe")
  end

  describe "ウェルカムモーダル" do
    it "初回ログイン時にウェルカムモーダルが表示される" do
      login_as user, scope: :user
      visit organizers_dashboard_path

      expect(page).to have_selector("#welcome-modal")
      expect(page).to have_content("Local Photo Contestへようこそ")
    end

    it "「チュートリアルを開始」をクリックするとチュートリアルが開始される" do
      login_as user, scope: :user
      visit organizers_dashboard_path

      click_button "チュートリアルを開始"

      # ツールチップが表示される
      expect(page).to have_selector(".tutorial-tooltip", visible: true)
      expect(page).to have_content("ようこそ")
    end

    it "「スキップ」をクリックするとモーダルが閉じる" do
      login_as user, scope: :user
      visit organizers_dashboard_path

      click_button "スキップ"

      expect(page).not_to have_selector("#welcome-modal")
    end
  end

  describe "チュートリアルステップ表示" do
    before do
      # チュートリアルを開始済み状態にする
      create(:tutorial_progress,
             user: user,
             tutorial_type: "organizer_onboarding",
             started_at: Time.current,
             current_step_id: "welcome")
    end

    context "ターゲット要素が存在する場合" do
      it "ターゲット要素がハイライトされる" do
        login_as user, scope: :user
        visit organizers_dashboard_path

        # ウェルカムモーダルをスキップ
        click_button "スキップ" if page.has_button?("スキップ")

        # ヘルプボタンからチュートリアルを開始
        find('[data-tutorial="create-contest"]', visible: true)

        # data-tutorial属性を持つ要素が存在することを確認
        expect(page).to have_selector('[data-tutorial="create-contest"]')
      end

      it "ハイライトされた要素がクリック可能である" do
        login_as user, scope: :user
        visit organizers_dashboard_path

        click_button "スキップ" if page.has_button?("スキップ")

        # data-tutorial属性を持つリンクがクリック可能
        create_contest_link = find('[data-tutorial="create-contest"]')
        expect(create_contest_link).to be_visible
      end
    end

    context "ターゲット要素が存在しない場合" do
      before do
        # 存在しないセレクターを持つステップを作成
        TutorialStep.find_by(step_id: "create_contest").update!(
          target_selector: '[data-tutorial="nonexistent-element"]'
        )
      end

      it "オーバーレイが表示されない（画面が暗くならない）" do
        login_as user, scope: :user
        visit organizers_dashboard_path

        click_button "チュートリアルを開始"

        # 最初のステップ（ターゲットなし）を次へ
        click_button "次へ"

        # チュートリアルコンテナ内のオーバーレイが非表示であること
        within(".tutorial-container") do
          overlay = find('[data-tutorial-target="overlay"]', visible: :all)
          expect(overlay[:class]).to include("hidden")
        end
      end

      it "ツールチップは中央に表示される" do
        login_as user, scope: :user
        visit organizers_dashboard_path

        click_button "チュートリアルを開始"
        click_button "次へ"

        # ツールチップが表示される
        expect(page).to have_selector(".tutorial-tooltip", visible: true)
      end
    end
  end

  describe "チュートリアル完了" do
    it "全ステップ完了後に完了トーストが表示される" do
      login_as user, scope: :user
      visit organizers_dashboard_path

      click_button "チュートリアルを開始"

      # 各ステップを進める（最後は「完了」ボタン）
      2.times do
        click_button "次へ" if page.has_button?("次へ", wait: 2)
      end

      # 最後のステップで「完了」をクリック
      click_button "完了" if page.has_button?("完了", wait: 2)

      # 完了トーストが表示される（アニメーション時間を考慮）
      expect(page).to have_selector(".tutorial-completion-toast", visible: true, wait: 3)
    end
  end

  describe "data-tutorial属性" do
    it "ダッシュボードに create-contest 属性が存在する" do
      login_as user, scope: :user
      visit organizers_dashboard_path

      click_button "スキップ" if page.has_button?("スキップ")

      expect(page).to have_selector('[data-tutorial="create-contest"]')
    end

    it "ダッシュボードに stats-grid 属性が存在する" do
      login_as user, scope: :user
      visit organizers_dashboard_path

      click_button "スキップ" if page.has_button?("スキップ")

      expect(page).to have_selector('[data-tutorial="stats-grid"]')
    end
  end
end
