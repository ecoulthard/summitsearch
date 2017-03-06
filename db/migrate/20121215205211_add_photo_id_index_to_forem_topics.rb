class AddPhotoIdIndexToForemTopics < ActiveRecord::Migration
  def change
    add_index :forem_topics, :album_id
    add_index :forem_topics, :photo_id
    add_index :forem_topics, :trip_report_id
  end
end
