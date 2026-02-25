# frozen_string_literal: true

class HelpController < ApplicationController
  # Allow access without authentication
  skip_before_action :authenticate_user!, raise: false

  VALID_GUIDES = %w[participant organizer judge admin].freeze

  def index
    @guides = helpers.guide_info
  end

  def show
    @guide_key = params[:guide]

    unless VALID_GUIDES.include?(@guide_key)
      raise ActionController::RoutingError, "Guide not found"
    end

    @guide = helpers.guide_info(@guide_key)
    @file_path = helpers.guide_file_path(@guide_key)

    unless @file_path && File.exist?(@file_path)
      raise ActionController::RoutingError, "Guide file not found"
    end

    @content = helpers.render_markdown(@file_path)
    @toc = helpers.extract_toc(@file_path)
  end
end
