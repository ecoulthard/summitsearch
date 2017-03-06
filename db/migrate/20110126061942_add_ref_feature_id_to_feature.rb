class AddRefFeatureIdToFeature < ActiveRecord::Migration
  def self.up
    add_column :features, :ref_feature_id, :integer
    add_column :features, :ref_area_id, :integer
  end

  def self.down
    remove_column :features, :ref_feature_id
    remove_column :features, :ref_area_id
  end
end
