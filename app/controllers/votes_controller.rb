# frozen_string_literal: true

class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry
  before_action :check_voting_allowed, only: [ :create ]

  def create
    @vote = @entry.votes.build(user: current_user)

    if @vote.save
      MilestoneService.new(current_user).check_and_award(:vote, { entry_id: @entry.id })
      PointService.new(current_user).award_for_action("vote", source: @vote)
      respond_to do |format|
        format.html { redirect_to @entry, notice: t('flash.votes.created') }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @entry, alert: @vote.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("vote_button_#{@entry.id}", partial: "votes/button", locals: { entry: @entry }) }
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition - vote already exists at database level
    respond_to do |format|
      format.html { redirect_to @entry, alert: t('flash.votes.already_voted') }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("vote_button_#{@entry.id}", partial: "votes/button", locals: { entry: @entry }) }
    end
  end

  def destroy
    @vote = @entry.votes.find_by(user: current_user)

    if @vote&.destroy
      respond_to do |format|
        format.html { redirect_to @entry, notice: t('flash.votes.destroyed') }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @entry, alert: t('flash.votes.failed') }
        format.turbo_stream
      end
    end
  end

  private

  def set_entry
    @entry = Entry.find(params[:entry_id])
  end

  def check_voting_allowed
    return if @entry.contest.accepting_entries?

    respond_to do |format|
      format.html { redirect_to @entry, alert: t('flash.votes.voting_closed') }
      format.turbo_stream { head :unprocessable_entity }
    end
  end
end
