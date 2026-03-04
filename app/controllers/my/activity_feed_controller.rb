# frozen_string_literal: true

module My
  class ActivityFeedController < ApplicationController
    before_action :authenticate_user!

    def index
      service = ActivityFeedService.new(current_user)
      @feed = service.feed(page: params[:page] || 1)
      @following_count = current_user.following_count
    end
  end
end
