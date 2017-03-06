class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name, :null => false, :limit => 128
      t.string :photo_file_name
      t.string :photo_content_type
      t.integer :photo_file_size
      t.datetime :photo_updated_at
      t.string :photo_caption
      t.text :description
      t.text :references
      t.datetime :birthdate
      t.datetime :deathdate
      t.string :slug
      t.integer :importance
      t.integer :insert_id, :null => false
      t.integer :update_id

      t.timestamps
    end
    add_index :people, :slug, :unique => true
    add_index :people, :insert_id
    add_index :people, :update_id
  end
end
