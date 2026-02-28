# frozen_string_literal: true

class DataExportCleanupJob < ApplicationJob
  queue_as :default

  def perform
    DataExportRequest.completed.where("expires_at < ?", Time.current).find_each do |export|
      export.file.purge if export.file.attached?
      export.update!(status: :expired)
    rescue => e
      Rails.logger.error("Data export cleanup failed for request ##{export.id}: #{e.message}")
    end
  end
end
