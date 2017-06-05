class UpdatePhotoRefFieldsAllowNullable < ActiveRecord::Migration
  def change
    change_column :photos, :ref_latitude, :decimal, :null => true, :precision => 8, :scale => 6
    change_column :photos, :ref_longitude, :decimal, :null => true, :precision => 9, :scale => 6
    change_column :photos, :ref_title, :string, :null => true, :limit => 128
    change_column :photos, :ref_content, :string, :null => true, :limit => 1024
  end
end
