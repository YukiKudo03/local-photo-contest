class AddJudgingSettingsToContests < ActiveRecord::Migration[8.0]
  def change
    add_column :contests, :judging_method, :integer, default: 0, null: false
    add_column :contests, :judge_weight, :integer, default: 70
    add_column :contests, :prize_count, :integer, default: 3
    add_column :contests, :show_detailed_scores, :boolean, default: false
  end
end
