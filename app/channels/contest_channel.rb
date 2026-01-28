# frozen_string_literal: true

class ContestChannel < ApplicationCable::Channel
  def subscribed
    contest = Contest.find(params[:contest_id])
    stream_for contest
  end

  def unsubscribed
    stop_all_streams
  end
end
