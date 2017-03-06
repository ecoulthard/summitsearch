class AddWidthToPhoto < ActiveRecord::Migration
  def change
    add_column :photos, :photo_width, :integer
    add_column :photos, :photo_height, :integer
  end
end
