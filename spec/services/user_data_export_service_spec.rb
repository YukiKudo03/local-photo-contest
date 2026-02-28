# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDataExportService, type: :service do
  let(:user) { create(:user, :confirmed, name: "Test User", bio: "Hello world") }
  let(:service) { described_class.new(user) }

  describe "#generate" do
    it "returns a hash with profile data" do
      data = service.generate
      expect(data[:profile][:email]).to eq(user.email)
      expect(data[:profile][:name]).to eq("Test User")
    end

    it "includes contests data" do
      create(:contest, user: user, title: "My Contest")
      data = service.generate
      expect(data[:contests].length).to eq(1)
      expect(data[:contests].first[:title]).to eq("My Contest")
    end

    it "includes entries data" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      create(:entry, user: user, contest: contest, title: "My Photo")
      data = service.generate
      expect(data[:entries].length).to eq(1)
      expect(data[:entries].first[:title]).to eq("My Photo")
    end

    it "includes votes data" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      entry = create(:entry, user: organizer, contest: contest)
      create(:vote, user: user, entry: entry)
      data = service.generate
      expect(data[:votes].length).to eq(1)
    end

    it "includes comments data" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      entry = create(:entry, user: organizer, contest: contest)
      create(:comment, user: user, entry: entry, body: "Nice photo!")
      data = service.generate
      expect(data[:comments].length).to eq(1)
      expect(data[:comments].first[:body]).to eq("Nice photo!")
    end

    it "includes notifications data" do
      create(:notification, user: user)
      data = service.generate
      expect(data[:notifications].length).to eq(1)
    end

    it "includes terms_acceptances data" do
      terms = create(:terms_of_service)
      create(:terms_acceptance, user: user, terms_of_service: terms)
      data = service.generate
      expect(data[:terms_acceptances].length).to eq(1)
    end

    it "includes settings data" do
      data = service.generate
      expect(data[:settings]).to be_a(Hash)
    end
  end

  describe "#generate_zip" do
    it "returns a Tempfile containing a valid ZIP" do
      zip_file = service.generate_zip
      expect(zip_file).to be_a(Tempfile)
      entries = []
      Zip::File.open(zip_file.path) do |zip|
        zip.each { |entry| entries << entry.name }
      end
      expect(entries).to include("data.json")
    ensure
      zip_file&.close
      zip_file&.unlink
    end
  end
end
