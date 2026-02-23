# frozen_string_literal: true

class UpdateTutorialProgressForV2 < ActiveRecord::Migration[8.0]
  def change
    # 各ステップの滞在時間を記録
    add_column :tutorial_progresses, :step_times, :json, default: {}
    # スキップしたステップを記録
    add_column :tutorial_progresses, :skipped_steps, :json, default: []
    # 完了方法（completed / skipped_all / auto_completed）
    add_column :tutorial_progresses, :completion_method, :string
  end
end
