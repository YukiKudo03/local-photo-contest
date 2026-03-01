class AddDashboardSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :dashboard_settings, :json, default: {}
  end
end
