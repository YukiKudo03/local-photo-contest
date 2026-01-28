class CreateJudgeInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :judge_invitations do |t|
      t.references :contest, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.integer :status, default: 0, null: false
      t.datetime :invited_at, null: false
      t.datetime :responded_at
      t.references :invited_by, foreign_key: { to_table: :users }
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :judge_invitations, [ :contest_id, :email ], unique: true
    add_index :judge_invitations, :token, unique: true
  end
end
