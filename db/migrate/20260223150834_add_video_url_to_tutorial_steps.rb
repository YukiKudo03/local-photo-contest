class AddVideoUrlToTutorialSteps < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorial_steps, :video_url, :string
    add_column :tutorial_steps, :video_title, :string
  end
end
