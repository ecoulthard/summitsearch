class AddPhotoIdToForemTopics < ActiveRecord::Migration
  def change
    add_column :forem_topics, :album_id, :integer
    add_column :forem_topics, :photo_id, :integer
    add_column :forem_topics, :trip_report_id, :integer
  end
end
