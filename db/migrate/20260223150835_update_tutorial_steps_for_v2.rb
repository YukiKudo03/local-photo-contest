# frozen_string_literal: true

class UpdateTutorialStepsForV2 < ActiveRecord::Migration[8.0]
  def change
    # アクションタイプの追加（何をさせるか）
    add_column :tutorial_steps, :action_type, :string, default: 'observe'
    # 成功時のフィードバック設定
    add_column :tutorial_steps, :success_feedback, :json, default: {}
    # 推奨滞在時間（秒）
    add_column :tutorial_steps, :recommended_duration, :integer, default: 5
    # スキップ可能か
    add_column :tutorial_steps, :skippable, :boolean, default: true

    # インデックス追加（既存でなければ）
    unless index_exists?(:tutorial_steps, [:tutorial_type, :position])
      add_index :tutorial_steps, [:tutorial_type, :position]
    end
  end
end
