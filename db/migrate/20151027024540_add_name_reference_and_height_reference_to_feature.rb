class AddNameReferenceAndHeightReferenceToFeature < ActiveRecord::Migration
  def change
    add_column :features, :name_reference, :int, :limit => 1
    add_column :features, :height_reference, :int, :limit => 1
  end
end
