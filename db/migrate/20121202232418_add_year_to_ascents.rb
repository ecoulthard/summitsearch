class AddYearToAscents < ActiveRecord::Migration
  def change
    add_column :ascents, :year, :integer, :limit => 2
    add_column :ascents, :month, :integer, :limit => 1
    add_column :ascents, :day, :integer, :limit => 1
    remove_column :ascents, :date
  end
end
