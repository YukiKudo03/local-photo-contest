# frozen_string_literal: true

require "csv"

class StatisticsExportService
  UTF8_BOM = "\xEF\xBB\xBF"

  attr_reader :contest

  def initialize(contest)
    @contest = contest
    @stats_service = StatisticsService.new(contest)
  end

  # Daily statistics CSV with BOM for Excel compatibility
  def to_csv
    daily_data = build_daily_data

    csv_content = CSV.generate do |csv|
      csv << [ "日付", "応募数", "投票数", "累計応募数", "累計投票数" ]

      cumulative_entries = 0
      cumulative_votes = 0

      daily_data.each do |date, data|
        cumulative_entries += data[:entries]
        cumulative_votes += data[:votes]

        csv << [
          date.strftime("%Y-%m-%d"),
          data[:entries],
          data[:votes],
          cumulative_entries,
          cumulative_votes
        ]
      end
    end

    UTF8_BOM + csv_content
  end

  # Summary statistics CSV
  def summary_csv
    stats = @stats_service.summary_stats

    csv_content = CSV.generate do |csv|
      csv << [ "項目", "値" ]
      csv << [ "総応募数", stats[:total_entries] ]
      csv << [ "総投票数", stats[:total_votes] ]
      csv << [ "参加者数", stats[:total_participants] ]
      csv << [ "スポット数", stats[:total_spots] ]
      csv << [ "本日の応募増減", stats[:entries_change] || 0 ]
      csv << [ "本日の投票増減", stats[:votes_change] || 0 ]
    end

    UTF8_BOM + csv_content
  end

  # Entries detail CSV
  def entries_csv
    entries = contest.entries
                     .includes(:user, :spot, :votes)
                     .order(created_at: :desc)

    csv_content = CSV.generate do |csv|
      csv << [ "ID", "タイトル", "投稿者", "スポット", "投票数", "投稿日時", "モデレーション状態" ]

      entries.each do |entry|
        csv << [
          entry.id,
          entry.title.presence || "(無題)",
          entry.user.name,
          entry.spot&.name || "-",
          entry.votes.size,
          entry.created_at.in_time_zone("Tokyo").strftime("%Y-%m-%d %H:%M"),
          moderation_status_label(entry.moderation_status)
        ]
      end
    end

    UTF8_BOM + csv_content
  end

  # Spot statistics CSV
  def spots_csv
    spots = contest.spots
                   .includes(:entries, :spot_votes)
                   .order(votes_count: :desc)

    csv_content = CSV.generate do |csv|
      csv << [ "ID", "名前", "カテゴリ", "発掘ステータス", "応募数", "投票数", "発掘者", "認定日" ]

      spots.each do |spot|
        csv << [
          spot.id,
          spot.name,
          spot.category_name,
          discovery_status_label(spot.discovery_status),
          spot.entries.size,
          spot.votes_count,
          spot.discovered_by&.name || "-",
          spot.certified_at&.in_time_zone("Tokyo")&.strftime("%Y-%m-%d") || "-"
        ]
      end
    end

    UTF8_BOM + csv_content
  end

  private

  def build_daily_data
    daily_entries = contest.entries
                           .group_by_day(:created_at, time_zone: "Tokyo")
                           .count

    daily_votes = Vote.joins(entry: :contest)
                      .where(entries: { contest_id: contest.id })
                      .group_by_day(:created_at, time_zone: "Tokyo")
                      .count

    # Merge all dates
    all_dates = (daily_entries.keys + daily_votes.keys).uniq.sort

    all_dates.each_with_object({}) do |date, result|
      result[date] = {
        entries: daily_entries[date] || 0,
        votes: daily_votes[date] || 0
      }
    end
  end

  def moderation_status_label(status)
    case status
    when "moderation_pending" then "保留中"
    when "moderation_approved" then "承認済み"
    when "moderation_hidden" then "非表示"
    when "moderation_requires_review" then "要確認"
    else status
    end
  end

  def discovery_status_label(status)
    case status
    when "organizer_created" then "主催者作成"
    when "discovered" then "発掘済み"
    when "certified" then "認定済み"
    when "rejected" then "却下"
    else status
    end
  end
end
