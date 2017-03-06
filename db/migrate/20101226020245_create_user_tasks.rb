class CreateUserTasks < ActiveRecord::Migration
  def self.up
    create_table :user_tasks do |t|
      t.integer :user_id, :null => false
      t.integer :task_id, :null => false
      t.integer :rating, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :user_tasks
  end
end
