# frozen_string_literal: true

class GalleryController < ApplicationController
  def index
    @entries = EntryFilterService.new(base_entries, params).filter

    # Sort
    @entries = case params[:sort]
    when "popular"
                 @entries.left_joins(:votes)
                         .group("entries.id")
                         .order(Arel.sql("COUNT(votes.id) DESC"), "entries.created_at DESC")
    when "oldest"
                 @entries.order(created_at: :asc)
    else # newest (default)
                 @entries.order(created_at: :desc)
    end

    @entries = @entries.includes(:user, :contest, :area, :votes, photo_attachment: :blob)
                       .page(params[:page]).per(24)

    # For filter dropdowns (only needed for full page requests)
    unless turbo_frame_request?
      @contests = Contest.where(status: [ :published, :finished ]).active.order(created_at: :desc)
      @categories = Category.ordered
      @areas = Area.ordered
    end

    # Respond with just the entries partial for Turbo Frame requests
    if turbo_frame_request?
      render partial: "gallery/entries", layout: false
    end
  end

  private

  def base_entries
    Entry.visible
         .joins(:contest)
         .where(contests: { status: [ :published, :finished ], deleted_at: nil })
  end
end
