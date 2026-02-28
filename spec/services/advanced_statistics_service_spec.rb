# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdvancedStatisticsService, type: :service do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:service) { described_class.new(contest) }

  describe "#repeater_rate" do
    context "when no entries" do
      it "returns 0.0" do
        expect(service.repeater_rate).to eq(0.0)
      end
    end

    context "when all participants are first-timers" do
      it "returns 0.0" do
        user1 = create(:user, :confirmed)
        user2 = create(:user, :confirmed)
        create(:entry, contest: contest, user: user1)
        create(:entry, contest: contest, user: user2)

        expect(service.repeater_rate).to eq(0.0)
      end
    end

    context "when some participants are repeaters" do
      it "returns correct percentage" do
        other_contest = create(:contest, :published, user: organizer)
        repeater = create(:user, :confirmed)
        newcomer = create(:user, :confirmed)

        create(:entry, contest: other_contest, user: repeater)
        create(:entry, contest: contest, user: repeater)
        create(:entry, contest: contest, user: newcomer)

        expect(service.repeater_rate).to eq(50.0)
      end
    end

    context "when organizer has no other contests" do
      it "returns 0.0" do
        create(:entry, contest: contest, user: create(:user, :confirmed))
        expect(service.repeater_rate).to eq(0.0)
      end
    end
  end

  describe "#new_participant_trend" do
    it "returns empty hash when no entries" do
      expect(service.new_participant_trend).to eq({})
    end

    it "groups first-time participants by day" do
      user1 = create(:user, :confirmed)
      user2 = create(:user, :confirmed)
      create(:entry, contest: contest, user: user1, created_at: 2.days.ago)
      create(:entry, contest: contest, user: user2, created_at: 1.day.ago)

      result = service.new_participant_trend
      expect(result.values.sum).to eq(2)
    end

    it "does not count same user twice" do
      user = create(:user, :confirmed)
      create(:entry, contest: contest, user: user, created_at: 2.days.ago)
      create(:entry, contest: contest, user: user, created_at: 1.day.ago)

      result = service.new_participant_trend
      expect(result.values.sum).to eq(1)
    end
  end

  describe "#cohort_analysis" do
    it "returns empty hash when no entries" do
      expect(service.cohort_analysis).to eq({})
    end

    it "groups participants by registration month" do
      jan_user = create(:user, :confirmed, created_at: Time.zone.parse("2026-01-15"))
      feb_user = create(:user, :confirmed, created_at: Time.zone.parse("2026-02-10"))

      create(:entry, contest: contest, user: jan_user)
      create(:entry, contest: contest, user: feb_user)

      result = service.cohort_analysis
      expect(result).to have_key("2026-01")
      expect(result).to have_key("2026-02")
      expect(result["2026-01"][:count]).to eq(1)
      expect(result["2026-02"][:count]).to eq(1)
    end
  end

  describe "#submission_heatmap" do
    it "returns 7x24 matrix of zeros when no entries" do
      result = service.submission_heatmap
      expect(result.keys.size).to eq(7)
      result.each_value do |hours|
        expect(hours.keys.size).to eq(24)
        expect(hours.values.sum).to eq(0)
      end
    end

    it "correctly maps entries to day-of-week and hour" do
      wednesday_2pm = Time.zone.parse("2026-02-25 14:30:00")
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: wednesday_2pm)

      result = service.submission_heatmap
      expect(result[3][14]).to eq(1)
    end

    it "aggregates multiple entries in same timeslot" do
      monday_9am = Time.zone.parse("2026-02-23 09:15:00")
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: monday_9am)
      create(:entry, contest: contest, user: create(:user, :confirmed), created_at: monday_9am + 20.minutes)

      result = service.submission_heatmap
      expect(result[1][9]).to eq(2)
    end
  end

  describe "#area_comparison" do
    context "when organizer has no areas" do
      it "returns empty array" do
        expect(service.area_comparison).to eq([])
      end
    end

    context "when areas exist with entries" do
      it "returns entry count, vote count, and participant count per area" do
        area1 = create(:area, user: organizer, name: "エリアA")
        area2 = create(:area, user: organizer, name: "エリアB")
        user1 = create(:user, :confirmed)
        user2 = create(:user, :confirmed)

        entry1 = create(:entry, contest: contest, user: user1, area: area1)
        create(:entry, contest: contest, user: user2, area: area1)
        entry3 = create(:entry, contest: contest, user: user1, area: area2)

        create(:vote, entry: entry1, user: create(:user, :confirmed))
        create(:vote, entry: entry3, user: create(:user, :confirmed))
        create(:vote, entry: entry3, user: create(:user, :confirmed))

        result = service.area_comparison
        expect(result.size).to eq(2)

        area_a = result.find { |r| r[:name] == "エリアA" }
        area_b = result.find { |r| r[:name] == "エリアB" }

        expect(area_a[:entries]).to eq(2)
        expect(area_a[:votes]).to eq(1)
        expect(area_a[:participants]).to eq(2)

        expect(area_b[:entries]).to eq(1)
        expect(area_b[:votes]).to eq(2)
        expect(area_b[:participants]).to eq(1)
      end
    end

    context "when area has no entries in this contest" do
      it "returns zero counts" do
        create(:area, user: organizer, name: "空エリア")

        result = service.area_comparison
        expect(result.size).to eq(1)
        expect(result.first[:entries]).to eq(0)
        expect(result.first[:votes]).to eq(0)
        expect(result.first[:participants]).to eq(0)
      end
    end
  end

  describe "#area_participant_distribution" do
    it "returns empty hash when no areas" do
      expect(service.area_participant_distribution).to eq({})
    end

    it "returns participant count per area" do
      area1 = create(:area, user: organizer, name: "エリアA")
      area2 = create(:area, user: organizer, name: "エリアB")
      user1 = create(:user, :confirmed)
      user2 = create(:user, :confirmed)

      create(:entry, contest: contest, user: user1, area: area1)
      create(:entry, contest: contest, user: user2, area: area1)
      create(:entry, contest: contest, user: user1, area: area2)

      result = service.area_participant_distribution
      expect(result["エリアA"]).to eq(2)
      expect(result["エリアB"]).to eq(1)
    end
  end

  describe "#activity_score" do
    it "returns 0 when no activity" do
      area = create(:area, user: organizer)
      expect(service.activity_score(area)).to eq(0)
    end

    it "calculates weighted score" do
      area = create(:area, user: organizer)
      user1 = create(:user, :confirmed)
      user2 = create(:user, :confirmed)

      entry1 = create(:entry, contest: contest, user: user1, area: area)
      create(:entry, contest: contest, user: user2, area: area)
      create(:vote, entry: entry1, user: create(:user, :confirmed))

      # 2 entries * 1.0 + 1 vote * 0.5 + 2 participants * 2.0 = 6.5
      expect(service.activity_score(area)).to eq(6.5)
    end
  end
end
