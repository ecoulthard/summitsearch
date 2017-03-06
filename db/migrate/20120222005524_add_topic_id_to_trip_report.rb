class AddTopicIdToTripReport < ActiveRecord::Migration
  def change
    add_column :trip_reports, :topic_id, :integer
    add_index :trip_reports, :topic_id
  end
end
