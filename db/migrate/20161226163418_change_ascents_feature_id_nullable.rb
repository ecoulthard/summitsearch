class ChangeAscentsFeatureIdNullable < ActiveRecord::Migration
  def change
    change_column :ascents, :feature_id, :int, :null => true
  end
end
