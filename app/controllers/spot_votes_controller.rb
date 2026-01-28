# frozen_string_literal: true

class SpotVotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_spot
  before_action :check_voting_allowed, only: [ :create ]

  def create
    @vote = @spot.spot_votes.build(user: current_user)

    if @vote.save
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "投票しました。" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: @vote.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("spot_vote_button_#{@spot.id}", partial: "spots/vote_button", locals: { spot: @spot }) }
      end
    end
  end

  def destroy
    @vote = @spot.spot_votes.find_by(user: current_user)

    if @vote&.destroy
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "投票を取り消しました。" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "投票の取り消しに失敗しました。" }
        format.turbo_stream
      end
    end
  end

  private

  def set_spot
    @spot = Spot.find(params[:spot_id])
  end

  def check_voting_allowed
    unless @spot.voteable?
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "このスポットには投票できません。" }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end
end
