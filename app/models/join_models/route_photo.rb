class RoutePhoto < ApplicationRecord
  belongs_to :route, optional: true
  belongs_to :photo, optional: true
  validates :route_id, :photo_id, :presence => true
end
