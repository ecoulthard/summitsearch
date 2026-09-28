class RouteAlbum < ApplicationRecord
  belongs_to :route, optional: true
  belongs_to :album, optional: true
  validates :album_id, :route_id, :presence => true
end
