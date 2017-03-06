class RoutePhoto < ActiveRecord::Base
  belongs_to :route
  belongs_to :photo
  validates :route_id, :photo_id, :presence => true
end
