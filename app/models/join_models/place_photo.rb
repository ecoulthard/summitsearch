class PlacePhoto < ActiveRecord::Base
  belongs_to :place
  belongs_to :photo
  validates :place_id, :photo_id, :presence => true
end
