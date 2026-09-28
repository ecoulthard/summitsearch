class PlaceRouteInArea < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :route, optional: true
  validates :route_id, :place_id, :presence => true
end
