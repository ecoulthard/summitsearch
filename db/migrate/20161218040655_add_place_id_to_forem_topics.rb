class AddPlaceIdToForemTopics < ActiveRecord::Migration
  def change
    add_column :forem_topics, :place_id, :integer
  end
end
