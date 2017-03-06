class AddRouteIdToPhoto < ActiveRecord::Migration
  def self.up
    add_column :photos, :route_id, :integer
  end

  def self.down
    remove_column :photos, :route_id
  end
end
