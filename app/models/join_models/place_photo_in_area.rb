class PlacePhotoInArea < ActiveRecord::Base
  belongs_to :place
  belongs_to :photo
  validates :photo_id, :place_id, :presence => true
end
