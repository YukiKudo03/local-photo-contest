# frozen_string_literal: true

class SearchController < ApplicationController
  PER_PAGE = 20

  def index
    @query = params[:q].to_s.strip
    @type = params[:type].presence || "all"

    if @query.present?
      @contests = search_contests
      @entries = search_entries
      @spots = search_spots

      @contest_count = @contests.total_count
      @entry_count = @entries.total_count
      @spot_count = @spots.total_count
      @total_count = @contest_count + @entry_count + @spot_count
    else
      @contests = Contest.none.page(1)
      @entries = Entry.none.page(1)
      @spots = Spot.none.page(1)
      @contest_count = 0
      @entry_count = 0
      @spot_count = 0
      @total_count = 0
    end
  end

  private

  def search_contests
    results = Contest.active
                     .where(status: [ :published, :finished ])
                     .search(@query)
                     .order(created_at: :desc)

    if @type == "contests"
      results.page(params[:page]).per(PER_PAGE)
    else
      results.page(1).per(6)
    end
  end

  def search_entries
    results = Entry.visible
                   .joins(:contest)
                   .where(contests: { status: [ :published, :finished ], deleted_at: nil })
                   .search(@query)
                   .includes(:user, :contest, :votes, photo_attachment: :blob)
                   .order(created_at: :desc)

    if @type == "entries"
      results.page(params[:page]).per(PER_PAGE)
    else
      results.page(1).per(6)
    end
  end

  def search_spots
    results = Spot.joins(:contest)
                  .where(contests: { status: [ :published, :finished ], deleted_at: nil })
                  .certified_or_organizer
                  .search(@query)
                  .includes(:contest)
                  .order(created_at: :desc)

    if @type == "spots"
      results.page(params[:page]).per(PER_PAGE)
    else
      results.page(1).per(6)
    end
  end
end
