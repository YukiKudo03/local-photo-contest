# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderatable, type: :model do
  describe "photo validations" do
    let(:contest) { create(:contest, :published) }
    let(:user) { create(:user, :confirmed) }

    it "rejects invalid photo content type" do
      entry = build(:entry, contest: contest, user: user)
      entry.photo.attach(io: StringIO.new("fake"), filename: "test.txt", content_type: "text/plain")
      expect(entry).not_to be_valid
      expect(entry.errors[:photo]).to be_present
    end

    it "rejects photo larger than 10MB" do
      entry = build(:entry, contest: contest, user: user)
      entry.photo.attach(io: StringIO.new("x" * 11.megabytes), filename: "large.jpg", content_type: "image/jpeg")
      expect(entry).not_to be_valid
      expect(entry.errors[:photo]).to be_present
    end
  end
end
