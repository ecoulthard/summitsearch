class AddCreatedAtIndices < ActiveRecord::Migration
  def up
    add_index :features, [:type, :created_at]
    add_index :routes, [:type, :created_at]
    add_index :areas, [:type, :created_at]
    add_index :albums, :created_at
    add_index :photos, :created_at
    add_index :trip_reports, :created_at
    add_index :users, :created_at
  end

  def down
    remove_index :features, [:type, :created_at]
    remove_index :routes, [:type, :created_at]
    remove_index :areas, [:type, :created_at]
    remove_index :albums, :created_at
    remove_index :photos, :created_at
    remove_index :trip_reports, :created_at
    remove_index :users, :created_at
  end
end
