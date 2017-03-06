class CreateAscentPeople < ActiveRecord::Migration
  def change
    create_table :ascent_people do |t|
      t.integer :ascent_id, :null => false
      t.integer :person_id, :null => false
      t.boolean :guide, :null => false, :default => false
      t.boolean :leader, :null => false, :default => false
    end
    add_index :ascent_people, :ascent_id
    add_index :ascent_people, :person_id
  end
end
