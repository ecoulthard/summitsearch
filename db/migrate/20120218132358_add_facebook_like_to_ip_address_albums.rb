class AddFacebookLikeToIpAddressAlbums < ActiveRecord::Migration
  def change
    add_column :ip_address_albums, :facebook_like, :boolean, :default => false
    add_column :ip_address_albums, :google_plus, :boolean, :default => false
  end
end
