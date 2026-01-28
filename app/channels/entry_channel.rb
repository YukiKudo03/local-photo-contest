# frozen_string_literal: true

class EntryChannel < ApplicationCable::Channel
  def subscribed
    entry = Entry.find(params[:entry_id])
    stream_for entry
  end

  def unsubscribed
    stop_all_streams
  end
end
