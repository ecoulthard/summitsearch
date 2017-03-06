class AddNamedAfterPersonIdToNames < ActiveRecord::Migration
  def change
    add_column :names, :named_after_person_id, :int
    add_index :names, :named_after_person_id
  end
end
