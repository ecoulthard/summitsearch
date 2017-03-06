class PlaceRouteInArea < ActiveRecord::Base
  belongs_to :place
  belongs_to :route
  validates :route_id, :place_id, :presence => true
end
