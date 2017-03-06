class AddSignatureToUsers < ActiveRecord::Migration
  def change
    add_column :users, :signature, :text, :limit => 5000
    add_column :users, :forem_last_visit_at, :datetime
    add_column :users, :forem_first_visit_at, :datetime
  end
end
