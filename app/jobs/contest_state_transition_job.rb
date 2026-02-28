# frozen_string_literal: true

class ContestStateTransitionJob < ApplicationJob
  queue_as :default

  def perform
    auto_publish_contests
    auto_finish_contests
  end

  private

  def auto_publish_contests
    Contest.pending_auto_publish.find_each do |contest|
      ContestSchedulingService.new(contest).publish!
    rescue => e
      Rails.logger.error("Auto-publish failed for contest ##{contest.id}: #{e.message}")
    end
  end

  def auto_finish_contests
    Contest.pending_auto_finish.find_each do |contest|
      ContestSchedulingService.new(contest).finish!
    rescue => e
      Rails.logger.error("Auto-finish failed for contest ##{contest.id}: #{e.message}")
    end
  end
end
