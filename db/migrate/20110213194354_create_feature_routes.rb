class CreateFeatureRoutes < ActiveRecord::Migration
  def self.up
    create_table :feature_routes do |t|
      t.integer :feature_id
      t.integer :route_id
    end
    add_index :feature_routes, :feature_id
    add_index :feature_routes, :route_id
  end

  def self.down
    drop_table :feature_routes
  end
end
