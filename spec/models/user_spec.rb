# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:terms_acceptances).dependent(:destroy) }
    it { should have_many(:contests).dependent(:destroy) }
    it { should have_many(:entries).dependent(:destroy) }
    it { should have_many(:votes).dependent(:destroy) }
    it { should have_many(:voted_entries).through(:votes).source(:entry) }
    it { should have_many(:notifications).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:role) }
    it { should validate_length_of(:name).is_at_most(50) }
    it { should validate_length_of(:bio).is_at_most(500) }

    describe "name validation" do
      let(:user) { create(:user, :confirmed) }

      it "allows blank name" do
        user.name = ""
        expect(user).to be_valid
      end

      it "allows name up to 50 characters" do
        user.name = "a" * 50
        expect(user).to be_valid
      end

      it "rejects name longer than 50 characters" do
        user.name = "a" * 51
        expect(user).not_to be_valid
        expect(user.errors[:name]).to be_present
      end
    end

    describe "bio validation" do
      let(:user) { create(:user, :confirmed) }

      it "allows blank bio" do
        user.bio = ""
        expect(user).to be_valid
      end

      it "allows bio up to 500 characters" do
        user.bio = "a" * 500
        expect(user).to be_valid
      end

      it "rejects bio longer than 500 characters" do
        user.bio = "a" * 501
        expect(user).not_to be_valid
        expect(user.errors[:bio]).to be_present
      end
    end
  end

  describe "#display_name" do
    let(:user) { create(:user, :confirmed, email: "testuser@example.com") }

    context "when name is set" do
      it "returns the name" do
        user.name = "John Doe"
        expect(user.display_name).to eq("John Doe")
      end
    end

    context "when name is blank" do
      it "returns the email username part" do
        user.name = nil
        expect(user.display_name).to eq("testuser")
      end

      it "returns the email username when name is empty string" do
        user.name = ""
        expect(user.display_name).to eq("testuser")
      end
    end
  end

  describe "#initial" do
    let(:user) { create(:user, :confirmed, email: "testuser@example.com") }

    context "when name is set" do
      it "returns the first character uppercase" do
        user.name = "john"
        expect(user.initial).to eq("J")
      end
    end

    context "when name is blank" do
      it "returns the first character of email username uppercase" do
        user.name = nil
        expect(user.initial).to eq("T")
      end
    end
  end

  describe "#organizer?" do
    it "returns true for organizer role" do
      user = build(:user, role: :organizer)
      expect(user.organizer?).to be true
    end

    it "returns true for admin role" do
      user = build(:user, role: :admin)
      expect(user.organizer?).to be true
    end

    it "returns false for participant role" do
      user = build(:user, role: :participant)
      expect(user.organizer?).to be false
    end
  end

  describe "dashboard settings" do
    let(:user) { create(:user, :admin, :confirmed) }

    describe "#update_dashboard_settings" do
      it "merges new settings with existing ones" do
        user.update_dashboard_settings("widgets" => { "stats" => true })
        user.update_dashboard_settings("widgets" => { "charts" => false })
        expect(user.reload.dashboard_settings["widgets"]).to eq("stats" => true, "charts" => false)
      end
    end

    describe "#widget_visible?" do
      it "returns true by default for any widget" do
        expect(user.widget_visible?("stats")).to be true
        expect(user.widget_visible?("charts")).to be true
      end

      it "returns false when explicitly hidden" do
        user.update_dashboard_settings("widget_visibility" => { "charts" => false })
        expect(user.widget_visible?("charts")).to be false
      end

      it "returns true when explicitly shown" do
        user.update_dashboard_settings("widget_visibility" => { "stats" => true })
        expect(user.widget_visible?("stats")).to be true
      end
    end

    describe "#widget_order" do
      it "returns default order when not customized" do
        expect(user.widget_order).to eq(User::DEFAULT_WIDGET_ORDER)
      end

      it "returns custom order when set" do
        custom_order = %w[recent_entries stats charts recent_users recent_contests]
        user.update_dashboard_settings("widget_order" => custom_order)
        expect(user.widget_order).to eq(custom_order)
      end
    end
  end

  describe "avatar attachment" do
    let(:user) { create(:user, :confirmed) }

    it "can have an avatar attached" do
      expect(user).to respond_to(:avatar)
    end
  end
end
