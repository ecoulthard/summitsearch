class CreateIpAddressFeatures < ActiveRecord::Migration
  def change
    create_table :ip_address_features do |t|
      t.integer :ip_address_id, :null => false
      t.integer :feature_id, :null => false
      t.integer :visit_count, :default => 0

      t.timestamps
    end
    add_index :ip_address_features, :ip_address_id
    add_index :ip_address_features, :feature_id
  end
end
