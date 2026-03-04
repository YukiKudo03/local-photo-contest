# frozen_string_literal: true

class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    result = FollowService.new(current_user).follow(@user)
    respond_to do |format|
      if result[:success]
        format.html { redirect_to user_path(@user), notice: t("flash.follows.created") }
        format.turbo_stream
      else
        format.html { redirect_to user_path(@user), alert: t("flash.follows.#{result[:error]}") }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def destroy
    FollowService.new(current_user).unfollow(@user)
    respond_to do |format|
      format.html { redirect_to user_path(@user), notice: t("flash.follows.destroyed") }
      format.turbo_stream
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
