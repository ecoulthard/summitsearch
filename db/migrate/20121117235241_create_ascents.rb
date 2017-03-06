class CreateAscents < ActiveRecord::Migration
  def change
    create_table :ascents do |t|
      t.integer :feature_id, :null => false
      t.integer :route_id
      t.integer :ascent_index
      t.date :date, :null => false
      t.string :duration
      t.boolean :solo, :null => false, :default => false
      t.boolean :success, :null => false, :default => true
      t.boolean :other_participants, :null => false, :default => false
      t.text :description

      t.timestamps
    end
    add_index :ascents, :feature_id
    add_index :ascents, :route_id
  end
end
