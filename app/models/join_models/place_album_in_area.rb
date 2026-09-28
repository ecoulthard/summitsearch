class PlaceAlbumInArea < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :album, optional: true
  validates :album_id, :place_id, :presence => true
end
