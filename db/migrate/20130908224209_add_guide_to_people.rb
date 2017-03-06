class AddGuideToPeople < ActiveRecord::Migration
  def change
    add_column :people, :guide, :boolean, :default => false
  end
end
