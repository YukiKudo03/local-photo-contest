# frozen_string_literal: true

class AddJudgingReminderTrackingToContestJudges < ActiveRecord::Migration[8.0]
  def change
    add_column :contest_judges, :last_reminder_sent_at, :datetime
    add_column :contest_judges, :reminder_count, :integer, default: 0
  end
end
