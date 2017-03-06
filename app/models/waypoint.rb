class Waypoint < ActiveRecord::Base
  include GeographyHelper
  
  #Local index is unique for the route this point belongs to
  default_scope { order('local_index') }
  
  belongs_to :route
  
  MARKER_TYPES = %w(bicycle bridge camera campground caution cave glaciers hiker horsebackriding hotsprings hut meadows mountains pass rangerstation ski waterfalls water)

  validates :local_index, :parent_index, :latitude, :longitude, :presence => true
  validates :height, :numericality => {:greater_than_or_equal_to => 0, :less_than => 9000}, :if => :has_height?
  validates :latitude, :numericality => {:greater_than_or_equal_to => -90, :less_than_or_equal_to => 90}
  validates :longitude, :numericality => {:greater_than_or_equal_to => -180, :less_than_or_equal_to => 180}
  #This validation messes up removing points during an edit. What a mess they made of nested
  #attributes. Way too much time spent trying to fix their bugs.
  #validates_uniqueness_of :local_index, :scope => :route_id, :message => 'Waypoint must have a unique index for its route.'

  #Need to validate that the local_index < route.num_waypoints
  #Need to validate that parent_index < local_index

  def display?
    return !(title.blank? && description.blank? && icon.blank?)
  end

  def has_height?
    return !self.height.blank?
  end

  def parent
    route.waypoints[parent_index]
  end

  #Haversine Formula
  def dist lat2, lon2
    GeographyHelper.distance latitude, longitude, lat2, lon2
  end

  #Return first local_index waypoints within square radius
  def self.find_first_by_radius lat, lon, radius
    maxLat = GeographyHelper.maxLatitude lat, radius
    minLat = GeographyHelper.minLatitude lat, radius
    maxLon = GeographyHelper.maxLongitude lat, lon, radius
    minLon = GeographyHelper.minLongitude lat, lon, radius
    Waypoint.where("latitude > :minLat and latitude < :maxLat and longitude > :minLon and longitude < :maxLon and local_index = 0", {:minLat => minLat, :maxLat => maxLat, :minLon => minLon, :maxLon => maxLon})
  end

end
