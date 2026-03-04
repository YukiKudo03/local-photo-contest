class AddSocialCountersToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :followers_count, :integer, default: 0, null: false
    add_column :users, :following_count, :integer, default: 0, null: false
    add_column :users, :email_on_new_follower, :boolean, default: true, null: false
    add_column :users, :email_on_followed_entry, :boolean, default: true, null: false
  end
end
