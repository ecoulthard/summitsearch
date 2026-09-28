class PlacePhotoInArea < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :photo, optional: true
  validates :photo_id, :place_id, :presence => true
end
