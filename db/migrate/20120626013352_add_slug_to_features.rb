class AddSlugToFeatures < ActiveRecord::Migration
  def change
    add_column :features, :slug, :string
    add_index :features, :slug, :unique => true
  end
end
