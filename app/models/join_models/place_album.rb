class PlaceAlbum < ActiveRecord::Base
  belongs_to :place
  belongs_to :album
  validates :place_id, :album_id, :presence => true
end
