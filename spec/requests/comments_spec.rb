require 'rails_helper'

RSpec.describe "Comments", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:entry) { create(:entry, contest: contest) }
  let(:commenter) { create(:user, :confirmed) }

  describe "POST /entries/:entry_id/comments" do
    let(:valid_params) { { comment: { body: "素敵な写真ですね！" } } }
    let(:invalid_params) { { comment: { body: "" } } }

    context "when not signed in" do
      it "redirects to login page" do
        post entry_comments_path(entry), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in commenter }

      context "with valid params" do
        it "creates a comment" do
          expect {
            post entry_comments_path(entry), params: valid_params
          }.to change(Comment, :count).by(1)
        end

        it "redirects to entry page with success message" do
          post entry_comments_path(entry), params: valid_params
          expect(response).to redirect_to(entry_path(entry))
          expect(flash[:notice]).to eq("コメントを投稿しました。")
        end

        it "sets the current user as comment owner" do
          post entry_comments_path(entry), params: valid_params
          expect(Comment.last.user).to eq(commenter)
        end
      end

      context "with invalid params" do
        it "does not create a comment" do
          expect {
            post entry_comments_path(entry), params: invalid_params
          }.not_to change(Comment, :count)
        end

        it "redirects with alert" do
          post entry_comments_path(entry), params: invalid_params
          expect(response).to redirect_to(entry_path(entry))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "DELETE /entries/:entry_id/comments/:id" do
    context "when not signed in" do
      let!(:comment) { create(:comment, entry: entry, user: commenter) }

      it "redirects to login page" do
        delete entry_comment_path(entry, comment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as comment owner" do
      let!(:comment) { create(:comment, entry: entry, user: commenter) }

      before { sign_in commenter }

      it "destroys the comment" do
        expect {
          delete entry_comment_path(entry, comment)
        }.to change(Comment, :count).by(-1)
      end

      it "redirects with success message" do
        delete entry_comment_path(entry, comment)
        expect(response).to redirect_to(entry_path(entry))
        expect(flash[:notice]).to eq("コメントを削除しました。")
      end
    end

    context "when signed in as entry owner" do
      let(:other_user) { create(:user, :confirmed) }
      let!(:comment) { create(:comment, entry: entry, user: other_user) }

      before { sign_in entry.user }

      it "can delete other user's comment on own entry" do
        expect {
          delete entry_comment_path(entry, comment)
        }.to change(Comment, :count).by(-1)
      end
    end

    context "when signed in as another user" do
      let(:other_user) { create(:user, :confirmed) }
      let(:third_user) { create(:user, :confirmed) }
      let!(:comment) { create(:comment, entry: entry, user: other_user) }

      before { sign_in third_user }

      it "cannot delete the comment" do
        expect {
          delete entry_comment_path(entry, comment)
        }.not_to change(Comment, :count)
      end

      it "redirects with alert" do
        delete entry_comment_path(entry, comment)
        expect(response).to redirect_to(entry_path(entry))
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end
end
