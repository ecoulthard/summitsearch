class AddFeatureIdToForemTopic < ActiveRecord::Migration
  def change
    add_column :forem_topics, :feature_id, :int
    add_column :forem_topics, :area_id, :int
    add_index :forem_topics, :feature_id
    add_index :forem_topics, :area_id
  end
end
