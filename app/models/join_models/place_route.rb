class PlaceRoute < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :route, optional: true
  validates :place_id, :route_id, :presence => true
end
