class AddWinterAscentIndexToAscents < ActiveRecord::Migration
  def change
    add_column :ascents, :winter_ascent_index, :integer
    add_column :ascents, :route_ascent_index, :integer
    remove_column :ascents, :duration
  end
end
