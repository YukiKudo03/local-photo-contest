# frozen_string_literal: true

module Admin
  class SystemHealthController < BaseController
    def show
      @service = SystemHealthService.new
      @database = @service.database_status
      @storage = @service.storage_stats
      @queue = @service.queue_stats
      @app_info = @service.application_info
      @overall = @service.overall_status
    end
  end
end
