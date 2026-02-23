class AddTutorialSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :tutorial_settings, :json, default: {
      show_tutorials: true,
      show_context_help: true,
      reduced_motion: false
    }
  end
end
