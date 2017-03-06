class AddRefAreaIdToArea < ActiveRecord::Migration
  def self.up
    add_column :areas, :ref_area_id, :integer
    add_column :areas, :ref_feature_id, :integer
  end

  def self.down
    remove_column :areas, :ref_area_id
    remove_column :areas, :ref_feature_id
  end
end
