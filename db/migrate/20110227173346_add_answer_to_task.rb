class AddAnswerToTask < ActiveRecord::Migration
  def self.up
    add_column :tasks, :answer, :text
  end

  def self.down
    remove_column :tasks, :answer
  end
end
