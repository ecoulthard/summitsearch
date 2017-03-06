class RemoveGuideFromPeopleAscent < ActiveRecord::Migration
  def up
    remove_column :ascent_people, :guide
    remove_column :ascent_people, :leader
  end

  def down
    add_column :ascent_people, :guide, :boolean, :default => false
    add_column :ascent_people, :leader, :boolean, :default => false
  end
end
