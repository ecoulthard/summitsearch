class BorderPoint < ActiveRecord::Base

  include GeographyHelper
  belongs_to :place

  validates :local_index, :latitude, :longitude, :presence => true
  validates :latitude, :numericality => {:greater_than_or_equal_to => -90, :less_than_or_equal_to => 90}
  validates :longitude, :numericality => {:greater_than_or_equal_to => -180, :less_than_or_equal_to => 180}
  validates_uniqueness_of :latitude, :scope => [:place_id, :longitude], :message => 'Boundary Point must have unique latitude-longitude for this area.'

  #Need to validate that the local_index < area.num_waypoints

  #Local index is unique for the area this point belongs to
  default_scope { order('local_index') }

  #Haversine Formula
  def dist lat2, lon2
    GeographyHelper.distance latitude, longitude, lat2, lon2
  end

  def bearing lat2, lon2
    GeographyHelper.bearing latitude, longitude, lat2, lon2
  end



end
