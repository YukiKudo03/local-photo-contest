# frozen_string_literal: true

class AddSchedulingColumnsToContests < ActiveRecord::Migration[8.0]
  def change
    add_column :contests, :scheduled_publish_at, :datetime
    add_column :contests, :scheduled_finish_at, :datetime
    add_column :contests, :judging_deadline_at, :datetime
    add_column :contests, :archived_at, :datetime
    add_column :contests, :auto_archive_days, :integer, default: 90

    add_index :contests, :scheduled_publish_at
    add_index :contests, :scheduled_finish_at
    add_index :contests, :archived_at
  end
end
