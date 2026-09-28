class AreaPlace < ApplicationRecord
  belongs_to :area, :class_name => "Place", optional: true
  belongs_to :place, :class_name => "Place", optional: true
  validates :place_id, :area_id, :presence => true
end
