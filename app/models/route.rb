require 'find'

class Route < ActiveRecord::Base
  include Concerns::Viewable
  include Concerns::Visitable
  include GeographyHelper
  include ArticleMatchHelper
  include ActiveModel::Dirty
  #define_attribute_methods are attributes which we want to know if they change
  define_attribute_methods = [:name, :alternate_names, :distance, :height_gain, :height_loss, :gpx]
  versioned
  cattr_reader :per_page 
  @@per_page = 100
  belongs_to :user, :foreign_key => "insert_id"
  belongs_to :place

  belongs_to :updater, :foreign_key => "update_id", :class_name => "User"
  belongs_to :descent_route, :class_name => "Route"
  belongs_to :road, :class_name => "Road"
  has_many :names
  accepts_nested_attributes_for :names, :allow_destroy => true, :reject_if => lambda { |a| a[:name].blank? }, :limit => 50
  has_many :trip_reports, :dependent => :destroy
  has_many :waypoints, :dependent => :destroy
  has_many :trip_photos, :through => :trip_reports
  has_many :albums
  has_many :photos
  accepts_nested_attributes_for :trip_reports, :allow_destroy => false
  accepts_nested_attributes_for :waypoints, :allow_destroy => true, :reject_if => lambda { |a| a[:latitude].blank? }

  has_many :place_routes_in_areas, :dependent => :destroy, :class_name => "PlaceRouteInArea"
  has_many :areas, -> { order 'area'}, :through => :place_routes_in_areas, :source => :place
  has_one :icefield_route, :dependent => :destroy, :class_name => "PlaceRouteInArea"
  has_one :icefield, :through => :icefield_route, :class_name => "Icefield", :source => :place
  has_many :ranges, :through => :place_routes_in_areas, :class_name => "MountainRange", :source => :place
  has_many :regions, :through => :place_routes_in_areas, :class_name => "Region", :source => :place
  has_many :parks, :through => :place_routes_in_areas, :class_name => "Park", :source => :place
  has_one :island_route, :dependent => :destroy, :class_name => "PlaceRouteInArea"
  has_one :island, :through => :island_route, :class_name => "Island", :source => :place

  has_one :sub_region_route, :class_name => "PlaceRouteInArea"
  has_one :sub_region, -> { where('sub_region') }, :through => :sub_region_route, :class_name => "Place", :source => :place

  has_many :place_routes, :dependent => :destroy
  has_many :places, -> { order 'name' }, :through => :place_routes

  has_many :route_albums
  has_many :album_appearances, :through => :route_albums, :source => :album
  has_many :route_photos
  has_many :photo_appearances, :through => :route_photos, :source => :photo

  has_attached_file :gps, :url => "/system/routes/:attachment/:id/:style/:basename.:extension",  
  :path => ":rails_root/public/system/routes/:attachment/:id/:style/:basename.:extension"

  validates_attachment_size :gps, :less_than => 5.megabytes
  validates_attachment_content_type :gps, :content_type => ['application/gpx', 'application/gpx+xml', 'application/octet-stream']

  NAME_STATUS_TYPES = %w(Official Unofficial)
  DIFFICULTY_OPTIONS = ["Easy", "Moderate", "Difficult"]
  ALLOW_BRANCHES = true #Overloaded in subclasses.

  SORT_OPTIONS = {'distance' => 'distance DESC NULLS LAST', 'difficulty' => 'difficulty', 'name' => 'name', 'date_created' => 'created_at DESC', 'height_change' => 'height_gain + height_loss DESC NULLS LAST', 'average_steepness' => 'height_gain/distance DESC NULLS LAST'}
  DEFAULT_SORT = 'name'

  #Is the route allowed to link to a destination place. Overwritten in subclasses
  SHOW_DESTINATION_PLACE = true
  #Can you link the route to photos
  PHOTO_LINKABLE = false

  validates :insert_id, :type, :name, :name_status, :travel_time, :presence => true
  validates_inclusion_of :name_status, :in => NAME_STATUS_TYPES
  validates_length_of :name, maximum: 128
  validates_length_of :equipment, maximum: 30720
  validates_length_of :access, maximum: 30720
  validates_length_of :objective_hazard, maximum: 30720
  validates_length_of :description, maximum: 30720

  validate :must_have_at_least_three_waypoints
  validate :cannot_have_more_than_10000_waypoints 
  validate :waypoints_have_unique_index
  validate :waypoints_must_be_at_most_n_km_apart
  validate :not_duplicate_route

  before_validation :sortWaypoints
#before_validation :printWaypoints
  before_validation :labelPlaces
#before_create :setAscentApproachRoute
  before_save :trim_content
  before_save :set_importance
#  after_create :addCreateContributionTime
  after_save :setPlaces
  after_save :setAreas

  #class_inheritable_arrays can be added to or overwrittem by subclasses.
  #each subclass gets a copy. So changing the copy doesn't affect the other classes.

  #words that go before a name that are required to indicate that the route is in the article
  class_attribute :before_name_article_accept_strings
  #words that go before a name that indicate that the route is not in the article.
  #These words occur before the article_accepts_strings
  class_attribute :before_name_article_reject_strings 
  #These words occur after the article_accepts_strings
  class_attribute :after_name_article_reject_strings 
  #words to trim from the names to allow more matches like removing "Mount" from "Mount Columbia"
  class_attribute :article_trim_strings 
  self.before_name_article_accept_strings = DEFAULT_BEFORE_NAME_ARTICLE_ACCEPT_STRINGS
  self.before_name_article_reject_strings = DEFAULT_BEFORE_NAME_ARTICLE_REJECT_STRINGS
  #Each subclass will remove the apropriate items from this list so that they match
  self.after_name_article_reject_strings = DEFAULT_AFTER_NAME_ARTICLE_REJECT_STRINGS
  self.article_trim_strings = DEFAULT_ARTICLE_TRIM_STRINGS

  #Search friendly parameters
  def to_param
    "#{id}-#{name.parameterize}"
  end

  # A summary string to use for autocomplete
  def autocomplete_summary
    summary = "Route: #{name}"
    summary += " (" + alternate_names + ")" unless alternate_names.blank?
    summary += " - " + areas.first.name if areas.count > 0
    summary += " - " + areas.second.name if areas.count > 1
    summary += " - Dist: " + distance.to_s
    summary
  end

  #Returns all classes inheriting from Route by reading the routes directory.
  #For simplicity, I store all subclass definitions for Route in the routes directory
  def self.subclasses
    subclasses=[]
    path="#{Rails.root.to_s}/app/models/routes"
    Find.find(path) do |p|
      if FileTest.directory?(p) and p!=path
        Find.prune # dont recurse into directories
        next
      end
      subclasses << File.basename(p,".*").camelize.constantize if p =~ /.rb$/
    end
    subclasses.sort_by {|subclass| subclass.to_s }
  end
  
  def shortname
    name
  end

  def aliases
    ""
  end

  def set_importance
    self.importance = (photos.count + 1) * Math.sqrt(photo_appearances.count+2) * (trip_reports.count + 1)
  end

  #Looks for nearby places containing the trimmed name of this route in their title
  #If any are found then partial_name_match is set to false
  def set_partial_name_match
    return if waypoints.length == 0
    #Only need to compute partial name match if new or a name has changed.
    return unless self.id.nil? || self.name_changed? || self.alternate_names_changed?
    #For each place look for trimmed name inside the places full names
    Place.find_by_radius(averageLatitude, averageLongitude, 70).each do |place|
      next if place == self
      trimmed_names.each do |trimmed| #Look for trimmed names in neighbour places names
	place.raw_names.each do |name|
	  if name.match(trimmed)
	    self.partial_name_match = false
	    return
	  end
	end
      end
    end
    self.partial_name_match = true
  end

#  #After creating a route credit the maker with some amount of access time
#  def addCreateContributionTime
#    user.add_content_contribution_time User::NEW_ROUTE_CONTRIBUTION_AMOUNT
#  end

  #Print for debugging since we often have to do that for routes.
  #Bloody routes always causing problems.
  def printWaypoints
    puts "\nWaypoints for route: #{name}"
    waypoints.each do |waypoint|
      puts "waypoint_id #{waypoint.id}, local_index: #{waypoint.local_index}, parent_index: #{waypoint.parent_index}"
      puts "latitude: #{waypoint.latitude}, longitude: #{waypoint.longitude}, height: #{waypoint.height}"
    end
    puts "\n\nWaypoints minus removed for route: #{name}"
    waypoints_minus_removed.each do |waypoint|
      puts "waypoint_id #{waypoint.id}, local_index: #{waypoint.local_index}, parent_index: #{waypoint.parent_index}"
      puts "latitude: #{waypoint.latitude}, longitude: #{waypoint.longitude}, height: #{waypoint.height}"
    end
    puts "\n"
  end

  #Lets us use correct model_names for subclasses. Works as of rails 3.0.3
  #If something goes wrong with inheritance in future rails versions look here.
  def self.inherited(child)
    child.instance_eval do
      def model_name
        Route.model_name
      end
    end
    super
  end

  #My list function for model index pages.
  #Lists all models with title >= lower and <= upper
  def self.list sort=DEFAULT_SORT, lower=nil, upper=nil
    if !lower.nil? && !upper.nil? && sort=="Name" #Grab alphabetical interval of routes
      result = where("LEFT(name,:length) >= :lower AND LEFT(name,:length) <= :upper", {:lower => lower, :upper => upper, :length => lower.length }).order(SORT_OPTIONS[sort])
    else
      result = order(SORT_OPTIONS[sort])
    end
    
    if sort == 'average_steepness'
      result = result.where("distance > 0")
    end

    result
  end
  
  #Return routes with first waypoint within square radius
  #Subclasses may need to override this method
  def self.find_by_radius lat, lon, radius
    routes = []
    maxLat = GeographyHelper.maxLatitude lat, radius
    minLat = GeographyHelper.minLatitude lat, radius
    maxLon = GeographyHelper.maxLongitude lat, lon, radius
    minLon = GeographyHelper.minLongitude lat, lon, radius
    where("id IN (SELECT distinct(route_id) FROM waypoints WHERE latitude > :minLat and latitude < :maxLat and longitude > :minLon and longitude < :maxLon)", {:minLat => minLat, :maxLat => maxLat, :minLon => minLon, :maxLon => maxLon})
  end

  def averageLatitude
    avg = 0.0
    waypoints.each do |waypoint|
      avg += waypoint.latitude
    end
    avg /= waypoints.length if waypoints.length > 0
    avg
  end

  def averageLongitude
    avg = 0.0
    waypoints.each do |waypoint|
      avg += waypoint.longitude
    end
    avg /= waypoints.length if waypoints.length > 0
    avg
  end

  #Returns which forum to use for topics about this route.
  def forum
    area = areas.where("forum_id IS NOT NULL").order(:area).first
    area.nil? ? Forem::Forum.find_by_name("Other Regions") : area.forum
  end

  #Used by createAscentApproachRoutes
  def getSubRouteWaypoints index
    waypoint = waypoints[index]
    points = []
    while waypoint != null
      points << waypoint
      waypoint = waypoints[waypoint.parent_index]
    end
    points.reverse
  end

  #Return true if the waypoints have changed
  def waypoints_changed?
    changed = false
    waypoints.each do |waypoint|
      changed |= waypoint.changed? || waypoint.marked_for_destruction?
    end
    changed
  end

  #Used for bulk insert of waypoints from a gpx file. Called from the controller.
  def addWaypoints coordinates
    #First delete any existing waypoints
    Waypoint.delete waypoint_ids
    self.distance = 0
    self.height_gain = 0
    self.height_loss = 0
    parent = nil
    local_index = parent_index = 0
    lastPointDeleted = false #True if a point is deleted for being close to another existing point

    coordinates.split('</trkpt>').each_with_index do |coordinate|
      next if coordinate.index('lat="').nil? #Skip if entry does not contain coordinate data.
      lat_index = coordinate.index('lat="') + 'lat="'.length
      lat = coordinate[lat_index .. coordinate.index('"', lat_index)-1]
      lat = lat.to_f
      lon_index = coordinate.index('lon="') + 'lon="'.length
      lon = coordinate[lon_index .. coordinate.index('"', lon_index)-1]
      lon = lon.to_f
      height_index = coordinate.index('<ele>') + '<ele>'.length
      height = coordinate[height_index .. coordinate.index('</ele>', height_index)-1]
      height = height.to_f
      
      unless parent.nil?  #Unless first waypoint then compute distance and elev change
        dist = parent.dist lat, lon
	next if dist < 0.05 # Skip waypoint if less than 50m away from the parent waypoint.
        # Delete waypoint if less than 90m away from the grand parent waypoint
	grand_parent = waypoints[parent.parent_index]
        if grand_parent.dist(lat,lon) < 0.07
	  parent_index = grand_parent.local_index
	  parent = grand_parent
          lastPointDeleted = true
          next
        end
        #Only delete additional waypoints if the previous waypoint was deleted.
        #This allows a duplicate point to exist for closing loops.
        if lastPointDeleted
	  closeToAPreviousPoint = false
	  (waypoints - [parent,grand_parent]).each do |waypoint|
	    if waypoint.dist(lat,lon) < 0.5
	      closeToAPreviousPoint = true
	      parent_index = waypoint.local_index
	      parent = waypoint
	      lastPointDeleted = true
	      break
	    end
	  end
        end
	next if closeToAPreviousPoint # Want to filter out the return points. Only care about 1 way travel.
        lastPointDeleted = false
	self.distance += dist
        self.height_gain += height > parent.height ? (height - parent.height) : 0
        self.height_loss += height < parent.height ? (parent.height - height) : 0
      end
	
      parent = waypoints.build(:latitude => lat, :longitude => lon, :height => height, :local_index => local_index, :parent_index => parent_index, :distance => self.distance, :height_gain => self.height_gain, :height_loss => self.height_loss)
      parent_index = local_index
      local_index += 1
    end

    # Mark the first waypoint as the starting point.
    waypoints[0].title = "Start point" if waypoints.length > 0
  end

  protected

  #Links this route to areas this route passes through
  #Skip if waypoints haven't changed.
  def setAreas
    return unless self.distance_changed? || self.height_gain_changed? || self.height_loss_changed?
    PlaceRouteInArea.delete place_routes_in_area_ids
    Place.areas.all.each do |area|
      waypoints.each do |waypoint|
        if(area.inArea(waypoint.latitude, waypoint.longitude))
          PlaceRouteInArea.create(:place_id => area.id, :route_id => id)
	  break
        end
      end
    end
  end

  #Links this route to places this route gets close to.
  #If a waypoint is closer than 0.5km to a place or less than 3km to a lake or glacier
  #then link it. The waypoint must be close to the same height as lake to link to a lake.
  #Skip if waypoints haven't changed.
  def setPlaces
    return unless self.distance_changed? || self.height_gain_changed? || self.height_loss_changed?
    PlaceRoute.delete place_route_ids
    Place.find_by_radius(averageLatitude, averageLongitude, 70).each do |place|
      waypoints.each do |waypoint|
        if place.dist(waypoint.latitude, waypoint.longitude) <= 0.6 || ([Lake,Glacier,Pass,Meadow].include?(place.class)  && !waypoint.height.nil? && (place.height - waypoint.height).abs < 100 && place.dist(waypoint.latitude, waypoint.longitude) <= 2)
          PlaceRoute.create(:place_id => place.id, :route_id => id, :waypoint_index => waypoint.local_index)
	  break
        end
      end
    end
  end

  #If a waypoint is sufficiently close to a place and the waypoint is not labelled then
  #the waypoint gets the places title and icon.
  def labelPlaces
    return unless waypoints_changed?
    Place.find_by_radius(averageLatitude, averageLongitude, 50, 0).each do |place|
      minDistance = 400#km
      closestPoint = waypoints.first
      waypoints_minus_removed.each do |waypoint|
	distance = place.dist waypoint.latitude, waypoint.longitude
	if minDistance > distance
	  minDistance = distance
	  closestPoint = waypoint
	end
      end
      # Someone entered a point on the place. If a mountain then replace the height
      # with the correct value and adjust the height change to reflect the new value.
      # If the waypoint isn't labelled then give it the places title and icon.
      if minDistance < 0.3 && !closestPoint.height.nil?
	parent = waypoints_minus_removed[closestPoint.parent_index]
        if place.class == Mountain && parent.present?
          heightChange = closestPoint.height - parent.height
          self.height_gain -= heightChange > 0 ? heightChange : 0 unless self.height_gain.nil?
          self.height_loss -= heightChange < 0 ? -heightChange : 0 unless self.height_loss.nil?
        end
	closestPoint.height = place.height if place.class == Mountain
	closestPoint.icon = place.class::MARKER_ICON[0..-5] if closestPoint.icon.nil?
	closestPoint.title = place.name if closestPoint.title.nil?
        if place.class == Mountain && parent.present?
          heightChange = closestPoint.height - parent.height
          self.height_gain += heightChange > 0 ? heightChange : 0 unless self.height_gain.nil?
          self.height_loss += heightChange < 0 ? -heightChange : 0 unless self.height_loss.nil?
        end
      end
    end
  end

  #Starts at the last points and follows the parent back to the start if the count of the path
  #is different than the number of waypoints then another branch exists.
  def has_branches
    branch_found = false
    waypoints[1..-1].each do |waypoint|
      branch_found |= waypoint.parent_index != waypoint.local_index-1
    end
    branch_found
  end

  #New waypoints are not always sorted. 
  #We need 2 if statements for the unit tests and I am not joking.
  #Without the inner if statement we get an undefined method `sort' for nil:NilClass
  #Not sure how it gets nil between the first if statement and the sort but I guess it does. F'd up.
  def sortWaypoints
    if waypoints.present?
      waypoints = waypoints.sort { |a,b| a.local_index <=> b.local_index } if waypoints.present?
    end
  end

  #Returns all waypoints not marked for destruction 
  def waypoints_minus_removed
    points = []
    waypoints.each do |waypoint|
      points << waypoint if !waypoint.marked_for_destruction?
    end
    points
  end

private

  #Returns an error if the route doesn't have enough waypoints
  def must_have_at_least_three_waypoints 
    if(waypoints_minus_removed.length < 3)
      puts "You must enter at least 3 waypoints"
      errors.add(:waypoints, "You must enter at least 3 waypoints")
    end
  end

  #Returns an error if the route has too many waypoints
  def cannot_have_more_than_10000_waypoints 
    if(waypoints_minus_removed.length > 10000)
      puts "You cannot enter more than 10000 waypoints"
      errors.add(:waypoints, "You cannot enter more than 10000 waypoints")
    end
  end

  #Sets an error if any line segment is more than 50 in length for roads
  #20 km for anything else.
  def waypoints_must_be_at_most_n_km_apart
    self.waypoints_minus_removed.each do |waypoint|
      next if waypoint.parent_index.nil? || waypoint.parent_index < 0 || waypoint.parent_index == waypoint.local_index
      parent = waypoints_minus_removed[waypoint.parent_index]
      if !parent.nil? && type == 'Road' && waypoint.dist(parent.latitude, parent.longitude) > 50
	puts "cannot be more than 50km apart."
        errors.add(:waypoints, "cannot be more than 50km apart.")
      elsif !parent.nil? && type != 'Road' && waypoint.dist(parent.latitude, parent.longitude) > 20
	puts "cannot be more than 20km apart."
        errors.add(:waypoints, "cannot be more than 20km apart.")
      end
    end
  end

  #No 2 routes in a 20km radius can have the same name
  def not_duplicate_route
    return unless waypoints.length != 0 && self.name_changed? && self.name != "Trip route"
    Route.find_by_radius(waypoints.first.latitude,waypoints.first.longitude, 20).each do |route|
      next if self.id == route.id #Prevents self testing on update
      if route.name == name
	puts "There is already another #{type.titleize.tableize.singularize} in this area with that name. This #{type.titleize.tableize.singularize} might have already been submitted."
        errors.add(:route, "There is already another #{type.titleize.tableize.singularize} in this area with that name. This #{type.titleize.tableize.singularize} might have already been submitted.")
      end
    end
  end

  def waypoints_have_unique_index
    return if waypoints.length == 0
    self.waypoints_minus_removed.each_with_index do |waypoint1,i|
      self.waypoints_minus_removed.each_with_index do |waypoint2,j|
        if waypoint1.local_index == waypoint2.local_index && i != j
	  puts "Must have unique index."
          errors.add(:waypoints, "Must have unique index.")
        end
      end
    end
  end

end
