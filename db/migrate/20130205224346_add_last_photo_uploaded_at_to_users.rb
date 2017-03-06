class AddLastPhotoUploadedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_photo_uploaded_at, :datetime, :default => Time.now
  end
end
