# frozen_string_literal: true

module Admin
  class SystemHealthService
    def database_status
      {
        connected: ActiveRecord::Base.connection.active?,
        adapter: ActiveRecord::Base.connection.adapter_name,
        pool_size: ActiveRecord::Base.connection_pool.size
      }
    rescue StandardError => e
      { connected: false, error: e.message }
    end

    def storage_stats
      {
        blob_count: ActiveStorage::Blob.count,
        total_size: ActiveStorage::Blob.sum(:byte_size)
      }
    rescue StandardError
      { blob_count: 0, total_size: 0 }
    end

    def queue_stats
      available = solid_queue_available?
      stats = { available: available }

      if available
        stats[:pending] = SolidQueue::Job.where(finished_at: nil).count
        stats[:failed] = SolidQueue::FailedExecution.count
      end

      stats
    rescue StandardError
      { available: false }
    end

    def application_info
      {
        rails_version: Rails.version,
        ruby_version: RUBY_VERSION,
        environment: Rails.env
      }
    end

    def overall_status
      db = database_status
      return :unhealthy unless db[:connected]

      :healthy
    end

    private

    def solid_queue_available?
      defined?(SolidQueue::Job) &&
        ActiveRecord::Base.connection.table_exists?("solid_queue_jobs")
    rescue StandardError
      false
    end
  end
end
