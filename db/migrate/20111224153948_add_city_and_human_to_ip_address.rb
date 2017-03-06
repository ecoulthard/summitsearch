class AddCityAndHumanToIpAddress < ActiveRecord::Migration
  def change
    add_column :ip_addresses, :city, :string
    add_column :ip_addresses, :human, :boolean
  end
end
