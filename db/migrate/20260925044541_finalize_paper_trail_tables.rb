class FinalizePaperTrailTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :versions # Deletes the dead vestal_versions data
    execute "DROP SEQUENCE IF EXISTS versions_id_seq CASCADE"
    rename_table :paper_trail_versions, :versions # Renames paper trail to active standard
  end
end