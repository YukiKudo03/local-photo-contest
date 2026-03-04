# frozen_string_literal: true

class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry

  def create
    @result = ReactionService.new(current_user).toggle_like(@entry)
    respond_to do |format|
      format.html { redirect_to entry_path(@entry) }
      format.turbo_stream
    end
  end

  def destroy
    @result = ReactionService.new(current_user).toggle_like(@entry)
    respond_to do |format|
      format.html { redirect_to entry_path(@entry) }
      format.turbo_stream { render :create }
    end
  end

  private

  def set_entry
    @entry = Entry.find(params[:entry_id])
  end
end
