class AddForemStateToUser < ActiveRecord::Migration
  def change
    add_column :users, :forem_state, :string, :default => 'approved'
  end
end
