class AreaPlace < ActiveRecord::Base
  belongs_to :area, :class_name => "Place"
  belongs_to :place, :class_name => "Place"
  validates :place_id, :area_id, :presence => true
end
