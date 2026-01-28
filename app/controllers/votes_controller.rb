# frozen_string_literal: true

class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry
  before_action :check_voting_allowed, only: [ :create ]

  def create
    @vote = @entry.votes.build(user: current_user)

    if @vote.save
      respond_to do |format|
        format.html { redirect_to @entry, notice: "投票しました。" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @entry, alert: @vote.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("vote_button_#{@entry.id}", partial: "votes/button", locals: { entry: @entry }) }
      end
    end
  end

  def destroy
    @vote = @entry.votes.find_by(user: current_user)

    if @vote&.destroy
      respond_to do |format|
        format.html { redirect_to @entry, notice: "投票を取り消しました。" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @entry, alert: "投票の取り消しに失敗しました。" }
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
      format.html { redirect_to @entry, alert: "投票期間が終了しています。" }
      format.turbo_stream { head :unprocessable_entity }
    end
  end
end
