# frozen_string_literal: true

class RankingsController < ApplicationController
  def index
    @rankings = User.where("total_points > 0")
                    .includes(avatar_attachment: :blob)
                    .order(total_points: :desc, level: :desc)
                    .page(params[:page])
                    .per(20)
    @current_user_rank = current_user_rank if user_signed_in?
  end

  def monthly
    date = parse_month_date
    service = SeasonRankingService.new
    @rankings = service.monthly_rankings(date: date)
    @summary = service.season_summary(:monthly, date: date)
    @period_type = :monthly
    @date = date
    render :season
  end

  def quarterly
    date = parse_quarter_date
    service = SeasonRankingService.new
    @rankings = service.quarterly_rankings(date: date)
    @summary = service.season_summary(:quarterly, date: date)
    @period_type = :quarterly
    @date = date
    render :season
  end

  private

  def current_user_rank
    return nil unless current_user
    User.where("total_points > ?", current_user.total_points).count + 1
  end

  def parse_month_date
    if params[:year] && params[:month]
      Date.new(params[:year].to_i, params[:month].to_i, 1)
    else
      Date.current
    end
  end

  def parse_quarter_date
    if params[:year] && params[:quarter]
      month = (params[:quarter].to_i - 1) * 3 + 1
      Date.new(params[:year].to_i, month, 1)
    else
      Date.current
    end
  end
end
