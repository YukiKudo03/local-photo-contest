# frozen_string_literal: true

class AddCertificateTrackingToContestRankings < ActiveRecord::Migration[8.0]
  def change
    add_column :contest_rankings, :certificate_generated_at, :datetime
    add_column :contest_rankings, :winner_notified_at, :datetime
  end
end
