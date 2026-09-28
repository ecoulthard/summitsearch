class PlaceAlbum < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :album, optional: true
  validates :place_id, :album_id, :presence => true
end
