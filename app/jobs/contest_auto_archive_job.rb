# frozen_string_literal: true

class ContestAutoArchiveJob < ApplicationJob
  queue_as :default

  def perform
    Contest.pending_auto_archive.find_each do |contest|
      ContestArchiveService.new(contest).archive!
    rescue => e
      Rails.logger.error("Auto-archive failed for contest ##{contest.id}: #{e.message}")
    end
  end
end
