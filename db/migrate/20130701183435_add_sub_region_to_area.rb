class AddSubRegionToArea < ActiveRecord::Migration
  def change
    add_column :areas, :sub_region, :boolean, :default => false
  end
end
