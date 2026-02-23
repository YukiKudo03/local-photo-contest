# frozen_string_literal: true

class FeedbackController < ApplicationController
  before_action :authenticate_user!

  # POST /feedback/action
  def action
    action_type = params[:action_type]
    metadata = params[:metadata] || {}

    # マイルストーンチェック
    service = MilestoneService.new(current_user)
    service.check_and_award(action_type.to_sym, metadata.to_h)

    render json: {
      milestones: current_user.recent_milestones(3).map { |m| m.badge_info },
      feature_level: current_user.feature_level
    }
  end
end
