class AddEmailPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_on_entry_submitted, :boolean, default: true, null: false
    add_column :users, :email_on_comment, :boolean, default: true, null: false
    add_column :users, :email_on_vote, :boolean, default: false, null: false
    add_column :users, :email_on_results, :boolean, default: true, null: false
    add_column :users, :email_digest, :boolean, default: true, null: false
    add_column :users, :email_on_judging, :boolean, default: true, null: false
    add_column :users, :unsubscribe_token, :string
    add_index :users, :unsubscribe_token, unique: true
  end
end
