class AddForemLastVisitAtToIpAddresses < ActiveRecord::Migration
  def change
    add_column :ip_addresses, :forem_last_visit_at, :datetime
    add_column :ip_addresses, :forem_first_visit_at, :datetime
  end
end
