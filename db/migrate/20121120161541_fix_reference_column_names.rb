class FixReferenceColumnNames < ActiveRecord::Migration
  def change
    rename_column :areas, :referrences, :references
    rename_column :features, :referrences, :references
    rename_column :routes, :referrences, :references
  end
end
