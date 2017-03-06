class CreateNames < ActiveRecord::Migration
  def change
    create_table :names do |t|
      t.string :name, :null => false
      t.integer :person_id
      t.string :named_by_other
      t.integer :feature_id
      t.integer :area_id
      t.integer :route_id
      t.integer :year
      t.text :description
    end
    add_index :names, :person_id
    add_index :names, :feature_id
    add_index :names, :area_id
    add_index :names, :route_id
  end
end
