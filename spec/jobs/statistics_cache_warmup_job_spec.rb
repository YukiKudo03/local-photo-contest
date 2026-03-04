# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatisticsCacheWarmupJob, type: :job do
  describe "#perform" do
    let(:organizer) { create(:user, :organizer, :confirmed) }

    it "warms up cache for published contests" do
      contest = create(:contest, :published, user: organizer)

      stats_service = instance_double(StatisticsService)
      advanced_service = instance_double(AdvancedStatisticsService)

      allow(StatisticsService).to receive(:new).with(contest).and_return(stats_service)
      allow(AdvancedStatisticsService).to receive(:new).with(contest).and_return(advanced_service)
      allow(stats_service).to receive(:summary_stats)
      allow(advanced_service).to receive(:submission_heatmap)

      described_class.perform_now

      expect(stats_service).to have_received(:summary_stats)
      expect(advanced_service).to have_received(:submission_heatmap)
    end

    it "skips draft contests" do
      create(:contest, :draft, user: organizer)

      expect(StatisticsService).not_to receive(:new)
      described_class.perform_now
    end

    it "continues processing when a contest fails" do
      contest1 = create(:contest, :published, user: organizer)
      contest2 = create(:contest, :published, user: organizer)

      failing_service = instance_double(StatisticsService)
      allow(StatisticsService).to receive(:new).with(contest1).and_return(failing_service)
      allow(failing_service).to receive(:summary_stats).and_raise(StandardError, "test error")

      success_service = instance_double(StatisticsService)
      advanced_service = instance_double(AdvancedStatisticsService)
      allow(StatisticsService).to receive(:new).with(contest2).and_return(success_service)
      allow(AdvancedStatisticsService).to receive(:new).with(contest2).and_return(advanced_service)
      allow(success_service).to receive(:summary_stats)
      allow(advanced_service).to receive(:submission_heatmap)

      expect { described_class.perform_now }.not_to raise_error

      expect(success_service).to have_received(:summary_stats)
      expect(advanced_service).to have_received(:submission_heatmap)
    end

    it "is enqueued in the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
