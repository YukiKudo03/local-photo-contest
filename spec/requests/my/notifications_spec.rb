require 'rails_helper'

RSpec.describe "My::Notifications", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }

  describe "GET /my/notifications" do
    context "when not signed in" do
      it "redirects to login page" do
        get my_notifications_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "returns success" do
        get my_notifications_path
        expect(response).to have_http_status(:success)
      end

      it "displays only current user's notifications" do
        my_notification = create(:notification, user: user, title: "私の通知")
        other_notification = create(:notification, user: other_user, title: "他人の通知")

        get my_notifications_path

        expect(response.body).to include("私の通知")
        expect(response.body).not_to include("他人の通知")
      end

      it "displays notifications in recent order" do
        old_notification = create(:notification, user: user, title: "古い通知", created_at: 2.days.ago)
        new_notification = create(:notification, user: user, title: "新しい通知", created_at: 1.day.ago)

        get my_notifications_path

        expect(response.body.index("新しい通知")).to be < response.body.index("古い通知")
      end
    end
  end

  describe "GET /my/notifications/:id" do
    context "when signed in" do
      before { sign_in user }

      context "with contest notification" do
        let(:organizer) { create(:user, :organizer, :confirmed) }
        let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: 1.day.ago) }
        let(:notification) { create(:notification, user: user, notifiable: contest) }

        it "marks notification as read" do
          expect(notification.read_at).to be_nil
          get my_notification_path(notification)
          expect(notification.reload.read_at).not_to be_nil
        end

        it "shows notification details with link to contest results" do
          get my_notification_path(notification)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("リンク先を開く")
        end
      end

      context "with entry notification" do
        let(:organizer) { create(:user, :organizer, :confirmed) }
        let(:contest) { create(:contest, :published, user: organizer) }
        let!(:entry) { create(:entry, contest: contest, user: user) }
        let(:notification) { create(:notification, :entry_ranked, user: user, notifiable: entry) }

        before { contest.finish! }

        it "shows notification details with link to entry page" do
          get my_notification_path(notification)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("リンク先を開く")
        end
      end

      context "when accessing other user's notification" do
        let(:other_notification) { create(:notification, user: other_user) }

        it "returns not found" do
          get my_notification_path(other_notification)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "notification_redirect_path" do
    let(:controller_instance) do
      ctrl = My::NotificationsController.new
      # Provide url_options so route helpers work
      ctrl.define_singleton_method(:url_options) { { host: "localhost", port: 80 } }
      ctrl
    end

    it "returns contest results path for Contest notifiable" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :finished, user: organizer, results_announced_at: 1.day.ago)
      notification = create(:notification, user: user, notifiable: contest)

      path = controller_instance.send(:notification_redirect_path, notification)
      expect(path).to include("/contests/#{contest.id}/results")
    end

    it "returns entry path for Entry notifiable" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      entry = create(:entry, contest: contest, user: user)
      notification = create(:notification, :entry_ranked, user: user, notifiable: entry)

      path = controller_instance.send(:notification_redirect_path, notification)
      expect(path).to include("/entries/#{entry.id}")
    end

    it "returns notifications index path for unknown notifiable type" do
      notification = build(:notification, user: user, notifiable_type: "Unknown", notifiable_id: 1)

      path = controller_instance.send(:notification_redirect_path, notification)
      expect(path).to eq("/my/notifications")
    end
  end

  describe "POST /my/notifications/mark_all_as_read" do
    context "when signed in" do
      before { sign_in user }

      it "marks all notifications as read" do
        create_list(:notification, 3, user: user)
        expect(user.notifications.unread.count).to eq(3)

        post mark_all_as_read_my_notifications_path

        expect(user.notifications.unread.count).to eq(0)
      end

      it "redirects to notifications index" do
        post mark_all_as_read_my_notifications_path
        expect(response).to redirect_to(my_notifications_path)
      end

      it "shows success message" do
        post mark_all_as_read_my_notifications_path
        expect(flash[:notice]).to eq("すべての通知を既読にしました。")
      end
    end
  end
end
