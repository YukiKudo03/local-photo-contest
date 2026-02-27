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
      csv << [ I18n.t('services.export.date'), I18n.t('services.export.entries'), I18n.t('services.export.votes'), I18n.t('services.export.cumulative_entries'), I18n.t('services.export.cumulative_votes') ]

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
      csv << [ I18n.t('services.export.item'), I18n.t('services.export.value') ]
      csv << [ I18n.t('services.export.total_entries'), stats[:total_entries] ]
      csv << [ I18n.t('services.export.total_votes'), stats[:total_votes] ]
      csv << [ I18n.t('services.export.total_participants'), stats[:total_participants] ]
      csv << [ I18n.t('services.export.total_spots'), stats[:total_spots] ]
      csv << [ I18n.t('services.export.entries_change_today'), stats[:entries_change] || 0 ]
      csv << [ I18n.t('services.export.votes_change_today'), stats[:votes_change] || 0 ]
    end

    UTF8_BOM + csv_content
  end

  # Entries detail CSV
  def entries_csv
    entries = contest.entries
                     .includes(:user, :spot, :votes)
                     .order(created_at: :desc)

    csv_content = CSV.generate do |csv|
      csv << [ "ID", I18n.t('services.export.title'), I18n.t('services.export.submitter'), I18n.t('services.export.spot'), I18n.t('services.export.votes'), I18n.t('services.export.submitted_at'), I18n.t('services.export.moderation_status') ]

      entries.each do |entry|
        csv << [
          entry.id,
          entry.title.presence || I18n.t('common.untitled'),
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
      csv << [ "ID", I18n.t('services.export.name'), I18n.t('services.export.category'), I18n.t('services.export.discovery_status'), I18n.t('services.export.entries'), I18n.t('services.export.votes'), I18n.t('services.export.discoverer'), I18n.t('services.export.certified_date') ]

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
    I18n.t("services.export.moderation_statuses.#{status}", default: status)
  end

  def discovery_status_label(status)
    I18n.t("models.spot.discovery_statuses.#{status}", default: status)
  end
end
