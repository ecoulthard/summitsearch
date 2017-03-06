class CreateIpAddresses < ActiveRecord::Migration
  def self.up
    create_table :ip_addresses do |t|
      t.string :address, :null => false
      t.integer :user_id
      t.integer :visit_count, :null => false
      t.datetime :first_visit_at, :null => false
      t.datetime :last_visit_at, :null => false
      t.string :last_http_user_agent, :null => false
    end
    add_index :ip_addresses, :address
  end

  def self.down
    drop_table :ip_addresses
  end
end
