# frozen_string_literal: true

class WinnerNotificationService
  attr_reader :contest

  def initialize(contest)
    @contest = contest
  end

  def notify_winners!
    certificate_service = CertificateGenerationService.new

    prize_rankings.find_each do |ranking|
      next if ranking.winner_notified?

      entry = ranking.entry
      user = entry.user

      # Generate certificate
      certificate_service.generate_and_attach!(ranking)

      # Send email notification
      NotificationMailer.winner_certificate(user, ranking).deliver_later

      # Create in-app notification
      Notification.create_winner_certificate!(
        user: user,
        entry: entry,
        rank: ranking.rank
      )

      # Mark as notified
      ranking.update!(winner_notified_at: Time.current)
    rescue => e
      Rails.logger.error("Winner notification failed for ranking ##{ranking.id}: #{e.message}")
    end
  end

  private

  def prize_rankings
    contest.contest_rankings
           .where("rank <= ?", contest.prize_count || 3)
           .where(winner_notified_at: nil)
           .includes(entry: :user)
  end
end
