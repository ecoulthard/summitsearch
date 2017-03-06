class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string :title, :null => false, :limit => 64
      t.text :description, :null => false, :limit => 1024
      t.integer :user_id, :null => false
      t.string :task_type, :null => false
      t.integer :importance, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :tasks
  end
end
