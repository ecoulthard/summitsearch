class PlaceRoute < ActiveRecord::Base
  belongs_to :place
  belongs_to :route
  validates :place_id, :route_id, :presence => true
end
