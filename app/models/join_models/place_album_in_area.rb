class PlaceAlbumInArea < ActiveRecord::Base
  belongs_to :place
  belongs_to :album
  validates :album_id, :place_id, :presence => true
end
