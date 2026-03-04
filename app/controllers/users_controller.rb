# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    profile_service = UserProfileService.new(@user)
    @portfolio = profile_service.portfolio_entries
    @award_history = profile_service.award_history
    @stats = profile_service.stats
    @achievements = @user.milestones.recent
    @is_following = current_user&.following?(@user)
  end
end
