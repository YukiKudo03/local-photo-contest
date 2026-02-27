# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationMailer, type: :mailer do
  let(:contest) { create(:contest, :published, title: "テスト写真コンテスト") }
  let(:user) { create(:user, :confirmed) }

  describe "#entry_submitted" do
    let(:entry) { create(:entry, user: user, contest: contest, title: "桜の写真") }

    context "when email_on_entry_submitted is enabled" do
      it "sends email to the entry owner" do
        mail = described_class.entry_submitted(entry)
        expect(mail.to).to eq([ user.email ])
      end

      it "has correct subject" do
        mail = described_class.entry_submitted(entry)
        expect(mail.subject).to include("テスト写真コンテスト")
        expect(mail.subject).to include("応募が完了しました")
      end

      it "includes unsubscribe link" do
        mail = described_class.entry_submitted(entry)
        body = mail.body.parts.map(&:decoded).join
        expect(body).to include("メール通知設定を変更する")
      end
    end

    context "when email_on_entry_submitted is disabled" do
      before { user.update!(email_on_entry_submitted: false) }

      it "does not send email" do
        mail = described_class.entry_submitted(entry)
        expect(mail.to).to be_nil
      end
    end
  end

  describe "#comment_posted" do
    let(:entry) { create(:entry, user: user, contest: contest) }
    let(:commenter) { create(:user, :confirmed) }
    let(:comment) { create(:comment, entry: entry, user: commenter, body: "素敵な写真ですね") }

    context "when email_on_comment is enabled" do
      it "sends email to the entry owner" do
        mail = described_class.comment_posted(comment)
        expect(mail.to).to eq([ user.email ])
      end

      it "has correct subject" do
        mail = described_class.comment_posted(comment)
        expect(mail.subject).to include("コメントがつきました")
      end
    end

    context "when commenter is the entry owner" do
      let(:comment) { create(:comment, entry: entry, user: user, body: "自分のコメント") }

      it "does not send email" do
        mail = described_class.comment_posted(comment)
        expect(mail.to).to be_nil
      end
    end

    context "when email_on_comment is disabled" do
      before { user.update!(email_on_comment: false) }

      it "does not send email" do
        mail = described_class.comment_posted(comment)
        expect(mail.to).to be_nil
      end
    end
  end

  describe "#entry_voted" do
    let(:entry) { create(:entry, user: user, contest: contest) }
    let(:voter) { create(:user, :confirmed) }
    let(:vote) { create(:vote, entry: entry, user: voter) }

    context "when email_on_vote is enabled" do
      before { user.update!(email_on_vote: true) }

      it "sends email to the entry owner" do
        mail = described_class.entry_voted(vote)
        expect(mail.to).to eq([ user.email ])
      end
    end

    context "when email_on_vote is disabled (default)" do
      it "does not send email" do
        mail = described_class.entry_voted(vote)
        expect(mail.to).to be_nil
      end
    end
  end

  describe "#results_announced" do
    it "sends email to the user" do
      mail = described_class.results_announced(user, contest)
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to include("審査結果が発表されました")
    end

    context "when email_on_results is disabled" do
      before { user.update!(email_on_results: false) }

      it "does not send email" do
        mail = described_class.results_announced(user, contest)
        expect(mail.to).to be_nil
      end
    end
  end

  describe "#entry_ranked" do
    let(:entry) { create(:entry, user: user, contest: contest, title: "受賞作品") }

    it "sends email with rank info" do
      mail = described_class.entry_ranked(user, entry, 1)
      expect(mail.to).to eq([ user.email ])
      expect(mail.subject).to include("入賞おめでとうございます")
    end
  end

  describe "#daily_digest" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:entries) { [ create(:entry, contest: contest) ] }

    it "sends digest to organizer" do
      mail = described_class.daily_digest(organizer, { contest => entries })
      expect(mail.to).to eq([ organizer.email ])
      expect(mail.subject).to include("新規応募まとめ")
    end

    context "when email_digest is disabled" do
      before { organizer.update!(email_digest: false) }

      it "does not send email" do
        mail = described_class.daily_digest(organizer, { contest => entries })
        expect(mail.to).to be_nil
      end
    end
  end

  describe "#judging_reminder" do
    let(:judge_user) { create(:user, :confirmed) }
    let(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

    it "sends reminder to the judge" do
      mail = described_class.judging_reminder(contest_judge)
      expect(mail.to).to eq([ judge_user.email ])
      expect(mail.subject).to include("審査のリマインダー")
    end

    context "when email_on_judging is disabled" do
      before { judge_user.update!(email_on_judging: false) }

      it "does not send email" do
        mail = described_class.judging_reminder(contest_judge)
        expect(mail.to).to be_nil
      end
    end
  end

  describe "#judging_deadline" do
    let(:judge_user) { create(:user, :confirmed) }
    let(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

    it "sends deadline notice" do
      mail = described_class.judging_deadline(contest_judge, 3)
      expect(mail.to).to eq([ judge_user.email ])
      expect(mail.subject).to include("審査期限のお知らせ")
    end
  end
end
