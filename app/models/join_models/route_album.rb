class RouteAlbum < ActiveRecord::Base
  belongs_to :route
  belongs_to :album
  validates :album_id, :route_id, :presence => true
end
