class PlacePhoto < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :photo, optional: true
  validates :place_id, :photo_id, :presence => true
end
