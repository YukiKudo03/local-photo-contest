# frozen_string_literal: true

class AnalyticsReportJob < ApplicationJob
  queue_as :default

  def perform(contest_id = nil)
    contests = if contest_id
      Contest.where(id: contest_id)
    else
      Contest.where(status: [ :published, :finished ])
    end

    contests.find_each do |contest|
      AnalyticsReportService.new(contest).generate_and_attach!
    rescue StandardError => e
      Rails.logger.error("AnalyticsReportJob failed for contest #{contest.id}: #{e.message}")
    end
  end
end
