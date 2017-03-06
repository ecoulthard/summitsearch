class IncreasePhotoRefTitleLength < ActiveRecord::Migration
  def change
    change_column :photos, :ref_title, :string, :limit => 64
  end
end
