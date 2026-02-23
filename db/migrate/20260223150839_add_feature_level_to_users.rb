# frozen_string_literal: true

class AddFeatureLevelToUsers < ActiveRecord::Migration[8.0]
  def change
    # 機能開放レベル (beginner / intermediate / advanced)
    add_column :users, :feature_level, :string, default: 'beginner'

    add_index :users, :feature_level
  end
end
