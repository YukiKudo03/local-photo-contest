# frozen_string_literal: true

class SeasonRankingService
  def monthly_rankings(date: Time.current, limit: 50)
    period_start = date.beginning_of_month
    period_end = date.end_of_month
    build_rankings(period_start, period_end, limit)
  end

  def quarterly_rankings(date: Time.current, limit: 50)
    period_start = date.beginning_of_quarter
    period_end = date.end_of_quarter
    build_rankings(period_start, period_end, limit)
  end

  def season_summary(period_type, date: Time.current)
    period_start, period_end = period_bounds(period_type, date)
    points_in_period = UserPoint.for_period(period_start, period_end)

    {
      total_participants: points_in_period.select(:user_id).distinct.count,
      total_points_awarded: points_in_period.sum(:points),
      period_label: format_period_label(period_type, date),
      period_start: period_start,
      period_end: period_end
    }
  end

  private

  def build_rankings(period_start, period_end, limit)
    results = UserPoint.for_period(period_start, period_end)
                       .group(:user_id)
                       .select("user_id, SUM(points) as period_points")
                       .order("period_points DESC")
                       .limit(limit)

    users = User.where(id: results.map(&:user_id)).index_by(&:id)

    rank = 0
    prev_points = nil
    results.each_with_index.map do |result, index|
      points = result.period_points.to_i
      rank = index + 1 if points != prev_points
      prev_points = points
      {
        rank: rank,
        user: users[result.user_id],
        points: points
      }
    end
  end

  def period_bounds(period_type, date)
    case period_type
    when :monthly
      [ date.beginning_of_month, date.end_of_month ]
    when :quarterly
      [ date.beginning_of_quarter, date.end_of_quarter ]
    end
  end

  def format_period_label(period_type, date)
    case period_type
    when :monthly
      date.strftime("%Y-%m")
    when :quarterly
      quarter = ((date.month - 1) / 3) + 1
      "#{date.year} Q#{quarter}"
    end
  end
end
