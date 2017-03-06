class AddTopicIdToPhoto < ActiveRecord::Migration
  def change
    add_column :photos, :topic_id, :integer
    add_index :photos, :topic_id
  end
end
