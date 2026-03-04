# frozen_string_literal: true

class StatisticsCacheWarmupJob < ApplicationJob
  queue_as :default

  def perform
    Contest.published.find_each do |contest|
      StatisticsService.new(contest).summary_stats
      AdvancedStatisticsService.new(contest).submission_heatmap
    rescue => e
      Rails.logger.warn("Cache warmup failed for contest #{contest.id}: #{e.message}")
    end
  end
end
