class AddFacebookLikeToIpAddressPhotos < ActiveRecord::Migration
  def change
    add_column :ip_address_photos, :facebook_like, :boolean, :default => false
    add_column :ip_address_photos, :google_plus, :boolean, :default => false
  end
end
