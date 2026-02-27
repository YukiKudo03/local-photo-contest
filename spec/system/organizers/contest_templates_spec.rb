# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers Contest Templates", type: :system do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :draft, user: organizer, theme: "テストテーマ", prize_count: 5) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "template list" do
    context "when logged in as organizer" do
      before do
        login_as organizer, scope: :user
      end

      it "displays empty state when no templates" do
        visit organizers_contest_templates_path

        expect(page).to have_content("テンプレート一覧")
        expect(page).to have_content("テンプレートがありません")
      end

      it "displays templates list" do
        template = create(:contest_template, user: organizer, name: "マイテンプレート")

        visit organizers_contest_templates_path

        expect(page).to have_content("マイテンプレート")
        expect(page).to have_link("このテンプレートから作成")
      end

      it "can navigate to templates from sidebar" do
        visit organizers_contests_path

        click_link "テンプレート"

        expect(page).to have_current_path(organizers_contest_templates_path)
      end
    end
  end

  describe "saving template" do
    context "when logged in as organizer" do
      before do
        login_as organizer, scope: :user
      end

      it "saves a contest as template" do
        visit organizers_contest_path(contest)

        click_link "テンプレートとして保存"

        expect(page).to have_content("テンプレートとして保存")
        expect(page).to have_content(contest.title)

        fill_in "contest_template_name", with: "月例コンテスト設定"
        click_button "テンプレートを保存"

        expect(page).to have_content("テンプレートを保存しました")
        expect(page).to have_content("月例コンテスト設定")
      end

      it "shows error when template name is empty" do
        visit new_organizers_contest_template_path(contest_id: contest.id)

        fill_in "contest_template_name", with: ""
        click_button "テンプレートを保存"

        expect(page).to have_content("を入力してください")
      end

      it "displays saved settings preview" do
        visit new_organizers_contest_template_path(contest_id: contest.id)

        expect(page).to have_content("保存される設定")
        expect(page).to have_content("テストテーマ")
        expect(page).to have_content("5名")
      end
    end
  end

  describe "creating contest from template" do
    context "when logged in as organizer with templates" do
      let!(:template) do
        create(:contest_template,
          user: organizer,
          name: "テストテンプレート",
          theme: "テンプレートからのテーマ",
          prize_count: 7
        )
      end

      before do
        login_as organizer, scope: :user
      end

      it "displays template selector on new contest page" do
        visit new_organizers_contest_path

        expect(page).to have_content("テンプレートから作成")
        expect(page).to have_css("option", text: "テンプレートを選択...")
        expect(page).to have_css("option", text: /テストテンプレート/)
      end

      it "creates contest from template via list page" do
        visit organizers_contest_templates_path

        click_link "このテンプレートから作成"

        expect(page).to have_current_path(new_organizers_contest_path(template_id: template.id))
        expect(page).to have_content("「テストテンプレート」の設定がフォームにプリセットされました")
      end

      it "presets form values from template" do
        visit new_organizers_contest_path(template_id: template.id)

        expect(page).to have_field("contest_theme", with: "テンプレートからのテーマ")
      end
    end

    context "when logged in as organizer without templates" do
      before do
        login_as organizer, scope: :user
      end

      it "does not display template selector" do
        visit new_organizers_contest_path

        expect(page).not_to have_content("テンプレートから作成")
      end
    end
  end

  describe "deleting template" do
    context "when logged in as organizer" do
      let!(:template) { create(:contest_template, user: organizer, name: "削除対象テンプレート") }

      before do
        login_as organizer, scope: :user
      end

      it "deletes template with confirmation" do
        visit organizers_contest_templates_path

        expect(page).to have_content("削除対象テンプレート")

        accept_confirm do
          click_button "削除"
        end

        expect(page).to have_content("テンプレートを削除しました")
        expect(page).not_to have_content("削除対象テンプレート")
      end
    end
  end

  describe "access control" do
    context "when not logged in" do
      it "redirects to login page" do
        visit organizers_contest_templates_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context "when logged in as different organizer" do
      let(:other_organizer) { create(:user, :organizer, :confirmed) }
      let!(:template) { create(:contest_template, user: organizer, name: "他者のテンプレート") }

      before do
        login_as other_organizer, scope: :user
      end

      it "does not display other user's templates" do
        visit organizers_contest_templates_path

        expect(page).not_to have_content("他者のテンプレート")
        expect(page).to have_content("テンプレートがありません")
      end
    end
  end
end
