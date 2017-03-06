class AddGpsFileNameToRoutes < ActiveRecord::Migration
  def change
    add_column :routes, :gps_file_name, :string
    add_column :routes, :gps_content_type, :string
    add_column :routes, :gps_file_size, :integer
    add_column :routes, :gps_updated_at, :datetime
  end
end
