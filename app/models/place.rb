class Place < ActiveRecord::Base
  include Concerns::Viewable
  include Concerns::Visitable
  include GeographyHelper
  include ArticleMatchHelper
  include ActiveModel::Dirty

  #define_attribute_methods are attributes which we want to know if they change
  define_attribute_methods = [:name, :alternate_names, :area]

  versioned

  cattr_reader :per_page
  @@per_page = 100

  scope :large_first, -> { order('area DESC NULLS LAST') }
  scope :alphabetical, -> { order('name') }
  scope :recent_first, -> { order('created_at DESC') }
  scope :without_mountains, -> { where("type != 'Mountain'") }
  scope :without_mountains_huts, -> { where("type != 'Mountain' AND type != 'Hut'") }
  
  belongs_to :nearby_namesake, :class_name => "Place" #closest namesake

  belongs_to :user, :foreign_key => "insert_id"
  belongs_to :updater, :foreign_key => "update_id", :class_name => "User"

  has_many :names
  accepts_nested_attributes_for :names, :allow_destroy => true, :reject_if => lambda { |a| a[:name].blank? }, :limit => 50

  has_many :border_points, :dependent => :destroy
  has_many :unsorted_photos, :class_name => "Photo"

  #Places have and belong to many places.
  belongs_to :parent_area
  has_many :parent_area_places, :dependent => :destroy, :class_name => "AreaPlace", :foreign_key => "place_id"
  has_many :areas, :through => :parent_area_places

  has_many :child_area_places, :dependent => :destroy, :class_name => "AreaPlace", :foreign_key => "area_id"
  has_many :places, :through => :child_area_places

  has_one :icefield_place, :dependent => :destroy, :class_name => "AreaPlace", :foreign_key => "place_id"
  has_one :icefield, :through => :icefield_place, :class_name => "Icefield", :source => :area
  has_many :ranges, :through => :parent_area_places, :class_name => "MountainRange", :source => :area
  has_many :regions, :through => :parent_area_places, :class_name => "Region", :source => :area
  has_many :parks, :through => :parent_area_places, :class_name => "Park", :source => :area
  has_one :island_place, :dependent => :destroy, :class_name => "AreaPlace", :foreign_key => "place_id"
  has_one :island, :through => :island_place, :class_name => "Island", :source => :area
  has_one :mountain_place, :dependent => :destroy, :class_name => "AreaPlace", :foreign_key => "place_id"
  has_one :mountain, :through => :mountain_place, :class_name => "Mountain", :source => :area

  #Have to add these manually because a loop doesn't work. Possibly due to loading conditions.
  has_many :mountains, :through => :child_area_places, :class_name => "Mountain", :source => :place
  has_many :huts, :through => :child_area_places, :class_name => "Hut", :source => :place

#  Adding associations to self subclasses doesn't work. Possibly due to loading conditions. 
#  Place.subclasses.each do |subclass|
#    has_many subclass.to_s.tableize.to_sym, :through => :child_area_places, :class_name => subclass.to_s, :source => :place
#  end

  belongs_to :forum, :class_name => "Forem::Forum"
  
  has_many :place_routes, :dependent => :destroy
  has_many :routes, :through => :place_routes
  Route.subclasses.each do |subclass|
    has_many subclass.to_s.tableize.to_sym, :through => :place_routes, :class_name => subclass.to_s, :source => :route
  end

  has_many :trip_reports, :through => :routes
  #has_many :albums, -> { order 'created_at DESC' }
  has_many :place_albums
  has_many :album_appearances, -> { where("in_title=false") }, :through => :place_albums, :source => :album
  has_many :title_albums, -> { where("in_title=true").order("total_likes DESC NULLS LAST") }, :through => :place_albums, :source => :album
  has_many :place_photos
  has_many :photo_appearances, -> { where("in_title=false") }, :through => :place_photos, :source => :photo
  has_many :title_photos, -> { where("in_title=true").order("total_likes DESC NULLS LAST") }, :through => :place_photos, :source => :photo
  has_many :place_photos_in_area, :dependent => :destroy, :class_name => "PlacePhotoInArea"
  has_many :photos_in_area, -> { order 'created_at DESC' }, :through => :place_photos_in_area, :source => :photo
  has_many :place_albums_in_area, :dependent => :destroy, :class_name => "PlaceAlbumInArea"
  has_many :albums_in_area, -> { order 'created_at DESC' }, :through => :place_albums_in_area, :source => :album
  #has_many :area_albums, :dependent => :destroy
  #has_many :album_appearances, -> { order 'created_at DESC' }, :through => :area_albums, :source => :album
  #has_many :area_photos
  #has_many :photo_appearances, :through => :area_photos, :source => :photo
  #has_many :area_photos_in_area, :dependent => :destroy, :class_name => "AreaPhotoInArea"
  #has_many :photos_in_area, -> { order 'created_at DESC' }, :through => :area_photos_in_area, :source => :photo
  #has_many :area_albums_in_area, :dependent => :destroy, :class_name => "AreaAlbumInArea"
  #has_many :albums_in_area, -> { order 'created_at DESC' }, :through => :area_albums_in_area, :source => :album

  accepts_nested_attributes_for :border_points, :allow_destroy => true, :reject_if => lambda { |a| a[:latitude].blank? }, :limit => 2000

  #The radius we use to look for nearby name matches in articles.
  LARGE_LINKING_RADIUS = PlaceLinkingHelper::LARGE_LINKING_RADIUS
  NAME_STATUS_TYPES = %w(Official Unofficial Unnamed)
  NAME_SOURCE_TYPES = { :TopoMap => 1, :Canada => 2, :States => 3, :Summitsearch => 4, :Local => 5, :Wikipedia => 6, :GoogleMaps => 7, :KCountryGuide => 8, :SelkirksSouth => 9, :SelkirksNorth => 10, :WaterfallIceClimbs => 11, :MountainFootsteps => 12, :SnowshoeingCanadianRockies => 13, :SelkirkMountainExperience => 14, :CentralInteriorTrailGuide => 15, :GrandeCachePassportToThePeaks => 16, :MoreScrambles => 17, :CAJ => 18, :ClimbGreenland => 19, :SorcererLodge => 20, :SummitsAndIcefields => 21, :Clubtread => 22, :DTCHighwayGuide => 23, :SummitPost => 24, :Peakery => 25, :PeakBagger => 26, :AlpineSelect => 27, :SouthWestBCScrambles => 28, :RockiesCentral => 29, :RockiesSouth => 30, :RockiesWest => 31, :RockiesNorth => 32 }
  HEIGHT_MEASUREMENTS = %w(Meters Feet)
  COORDINATE_SYSTEMS = %w(Decimal Degrees:Minutes:Seconds)
  HEIGHT_SOURCE_TYPES = { :TopoMap => 1, :Google => 2, :Wikipedia => 3, :Averaged => 4, :Consistant => 5, :GoogleRounded10m => 6, :ClimbGreenland => 7, :CAJ => 8 }
  SORT_OPTIONS = {'area' => 'area DESC NULLS LAST', 'height' => 'height DESC NULLS LAST', 'name' => 'name', 'date_created' => 'created_at DESC'}
  DEFAULT_SORT = 'area'

  #Large areas are too big to have title photos. We will allow title photos for all areas
  #but not display them if the area is too big.
  MAX_AREA_FOR_TITLE_ARTICLES = 1200 #km^2

  validates :insert_id, :name, :name_status, :presence => true
  validates_inclusion_of :name_status, :in => NAME_STATUS_TYPES

  validates :height, :numericality => {:greater_than_or_equal_to => 0, :less_than => 9000, :allow_nil => true}
  validates :latitude, :numericality => {:greater_than_or_equal_to => -90, :less_than_or_equal_to => 90, :allow_nil => true}
  validates :longitude, :numericality => {:greater_than_or_equal_to => -180, :less_than_or_equal_to => 180, :allow_nil => true}
  validate :no_duplicate_places #Coordinates cannot be too close to existing places
  validate :must_have_at_least_three_border_points_or_center_point


  before_validation :setBoundingBox

  before_validation :sortBorderPoints
  before_save :setArea
  before_save :trim_content
  before_save :set_importance
  before_save :set_nearby_namesake # see function
  before_save :set_partial_name_match # see function
  #before_save :set_aliases # see function
  after_save :setPlaces
  after_save :setRoutes
  after_save :setPhotosInArea
  after_save :setAlbumsInArea
  after_create :addToAreas
#  after_create :addCreateContributionTime

  #class_inheritable_arrays can be added to or overwrittem by subclasses.
  #each subclass gets a copy. So changing the copy doesn't affect the other classes.

  #words that go before a name that are required to indicate that the place is in the article
  class_attribute :before_name_article_accept_strings
  #words that go before a name that indicate that the place is not in the article.
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

  extend FriendlyId
  friendly_id :slug_field, use: [:slugged, :finders]

  #Returns the slug to use for this place. It is based off of the name of the place.
  #The slug is a downcased shortname with - instead of spaces.
  #If there is already a place with that slug then attach the shortname of the largest area
  #the place is located in. Any collisions that we cannot resolve get resolved by the system
  #by adding numbers to each collision to make them unique.
  def slug_field
    return nil if name.nil?
    field = self.class == Mountain ? shortname : name
    field = field.downcase.gsub " ", "-"
    [
      field,
      field + "2",
      field + "3",
      field + "4",
      field + "5",
    ]
  end

  def shortname
    name
  end

  def aliases
    ""
  end

  # A summary string to use for autocomplete
  def autocomplete_summary
    summary = name
    summary += " (" + alternate_names + ")" unless alternate_names.blank?
    summary += " - " + areas.first.name if areas.count > 0
    summary += " - " + areas.second.name if areas.count > 1
    summary += " - Area: #{area.to_s} km^2" unless area.nil?
    summary += " - Height: " + height.to_s unless height.nil?
    summary
  end

  #Returns all classes inheriting from Place by reading the places directory.
  #For simplicity, I store all subclass definitions for Place in the places directory
  def self.subclasses
    subclasses=[]
    path="#{Rails.root.to_s}/app/models/places"
    Find.find(path) do |p|
      if FileTest.directory?(p) and p!=path
        Find.prune # dont recurse into directories
        next
      end
      subclasses << File.basename(p,".*").camelize.constantize if p =~ /.rb$/
    end
    subclasses.sort_by {|subclass| subclass.to_s }
  end

  def get_places_of_type type
    places.where("type=?", type.to_s) 
  end

  def has_places_of_type type
    get_places_of_type(type).present?
  end

 
#  #After creating an area credit the maker with some amount of access time
#  def addCreateContributionTime
#    user.add_content_contribution_time User::NEW_AREA_CONTRIBUTION_AMOUNT
#  end

  def set_importance
    self.importance = (unsorted_photos.count + 1) * Math.sqrt(photo_appearances.count+2) * (trip_reports.count + 1)
  end

  def set_nearby_namesake
    return unless self.id.nil? || self.name_changed?
    self.nearby_namesake_id = nil
    Place.find_by_radius(centerLatitude, centerLongitude, LARGE_LINKING_RADIUS).where(:type => self.type).each do |place|
      next if place == self
      if (self.trimmed_names & place.trimmed_names).any?
        #If this namesake is closer than the previous closer namesake. Make it is the new namesake
        if self.nearby_namesake_id.nil? || self.distance(nearby_namesake) > self.distance(place)
          self.nearby_namesake_id = place.id
          self.partial_name_match = false
	end
      end
    end
  end

  #Looks for nearby places containing the trimmed name of this place in their title
  #If any are found then partial_name_match is set to false
  #Also if the trimmed name is an english word then partial_name_match is set to false to
  #avoid false positives
  def set_partial_name_match
    return unless (self.id.nil? || self.name_changed?) && ((!self.latitude.nil? && !self.longitude.nil?) || border_points.length >= 3) 
    #For each place look for trimmed name inside the places full names
    Place.find_by_radius(centerLatitude, centerLongitude, LARGE_LINKING_RADIUS).each do |place|
      next if place == self
      trimmed_names.each do |trimmed|#Look for trimmed names in neighbour places names
	place.raw_names.each do |name|
	  if name.match(trimmed)
	    self.partial_name_match = false
	    return
	  end
	end
      end
    end
    #Load the dictionary
    words = {}
    File.open("public/words") do |file|
      file.each do |line|
        conv_line = (line + ' ').encode("UTF-8","iso-8859-1")[0..-2]
        words[conv_line.strip] = true
      end
    end
    #p words["magic"]
    #Look for trimmed names in the dictionary
    trimmed_names.each do |trimmed|
      if words[trimmed]
	self.partial_name_match = false
	return
      end
    end
    self.partial_name_match = true
  end

  #Lets us use correct model_names for subclasses. Works as of rails 3.0.3
  #If something goes wrong with inheritance in future rails versions look here.
  def self.inherited(child)
    child.instance_eval do
      def model_name
        Place.model_name
      end
    end
    super
  end

  #My list function for model index pages.
  #Lists all models with name >= lower and <= upper
  def self.list sort=DEFAULT_SORT, lower=nil, upper=nil
    if !lower.nil? && !upper.nil? && sort=="Name" #Grab alphabetical interval of places
      where("LEFT(name,:length) >= :lower AND LEFT(name,:length) <= :upper", {:lower => lower, :upper => upper, :length => lower.length }).order(SORT_OPTIONS[sort])
    else
      order(SORT_OPTIONS[sort])
    end
  end

  def self.areas
    where("Area > 0")
  end

  #Return places with at least one border point or center point in the square radius
  def self.find_by_radius lat, lon, radius, minHeight=0
    routes = []
    maxLat = GeographyHelper.maxLatitude lat, radius
    minLat = GeographyHelper.minLatitude lat, radius
    maxLon = GeographyHelper.maxLongitude lat, lon, radius
    minLon = GeographyHelper.minLongitude lat, lon, radius
    places = Place.find_by_bounding_box maxLat, minLat, maxLon, minLon
    places = places.where("height >= :minHeight", {:minHeight => minHeight}) if minHeight > 0
    places
  end

  def self.find_by_bounding_box maxLat, minLat, maxLon, minLon
    where("(latitude > :minLat and latitude < :maxLat and longitude > :minLon and longitude < :maxLon) OR id IN (SELECT distinct(place_id) FROM border_points WHERE latitude > :minLat and latitude < :maxLat and longitude > :minLon and longitude < :maxLon)", {:minLat => minLat, :maxLat => maxLat, :minLon => minLon, :maxLon => maxLon})
  end

  #Used for bulk insert of points
  def addPoints coordinates
    coordinates.split(',').each_with_index do |coordinate, index|
      border_points.build(:latitude => coordinate[0..coordinate.index(' ')-1], :longitude => coordinate[coordinate.index(' ')+1 .. coordinate.length-1], :local_index => index)
    end
  end

  #Sets the min,max latitude and longitude of the area for future use
  def setBoundingBox
    return unless border_points_minus_removed.any?
    self.max_latitude = -100 #max latitude
    self.min_latitude = 100 #min latitude
    self.max_longitude = -200 #max longitude
    self.min_longitude = 200 #min longitude
    border_points_minus_removed.each do |point|
      self.max_latitude = max_latitude > point.latitude ? max_latitude : point.latitude
      self.min_latitude = min_latitude < point.latitude ? min_latitude : point.latitude
      self.max_longitude = max_longitude > point.longitude ? max_longitude : point.longitude
      self.min_longitude = min_longitude < point.longitude ? min_longitude : point.longitude
    end
  end

  #Computes the area of the Area in km^2
  #A = 1/2 sum(x(i)y(i+1) - x(i+1)y(i))
  #Sets x(0) and y(0) = (0,0)
  def setArea
    return unless border_points_changed?
    self.area = 0
    return unless border_points_minus_removed.length >= 3
    centerLat = centerLatitude
    centerLong = centerLongitude
    last = border_points.last
    x1 = (last.longitude > centerLong ? 1 : -1) * (last.dist last.latitude, centerLong)
y1 = (last.latitude > centerLat ? 1 : -1) * (last.dist centerLat, last.longitude)
    sum = 0
    border_points_minus_removed.each_with_index do |point, index|
      x2 = (point.longitude > centerLong ? 1 : -1) * (point.dist point.latitude, centerLong)
y2 = (point.latitude > centerLat ? 1 : -1) * (point.dist centerLat, point.longitude)
      sum += x1*y2 - x2*y1
      x1 = x2
      y1 = y2
    end
    self.area = (sum/2).abs
  end

  def centerLatitude
    return latitude unless latitude.nil?
    return if border_points.count == 0
    avg = 0
    border_points.each do |point|
      avg += point.latitude
    end
    avg /= border_points.length
  end

  def centerLongitude
    return longitude unless longitude.nil?
    return if border_points.length == 0
    avg = 0
    border_points.each do |point|
      avg += point.longitude
    end
    avg /= border_points.length
  end

  #First clear existing links then add links to all places in this area
  def setPlaces

    return unless area_changed?
    AreaPlace.delete child_area_place_ids
    return unless area > 0

    places = Place.find_by_bounding_box max_latitude, min_latitude, max_longitude, min_longitude

    places.each do |place|
      if place.area.nil? || self.area > place.area
        #Add if center point is in this area
	if inArea(place.centerLatitude, place.centerLongitude)
          AreaPlace.create(:area_id => id, :place_id => place.id)
	end
      end
    end
  end

  #First clear existing links then add links to all routes in this area
  def setRoutes
    return unless area_changed?
    PlaceRoute.delete place_route_ids
    Route.all.each do |route|
      route.waypoints.each do |waypoint|
        if(inArea(waypoint.latitude, waypoint.longitude))
          PlaceRoute.create(:place_id => id, :route_id => route.id)
	  break
        end
      end
    end
  end

  #First clear existing links then add links to all photos in this area
  def setPhotosInArea
    return unless area_changed?
    PlacePhotoInArea.delete place_photos_in_area_ids
    Photo.all.each do |photo|
      if(inArea(photo.ref_latitude, photo.ref_longitude))
        PlacePhotoInArea.create(:place_id => id, :photo_id => photo.id)
      end
    end
  end


  #First clear existing links then add links to all albums in this area
  def setAlbumsInArea
    return unless area_changed?
    PlaceAlbumInArea.delete place_albums_in_area_ids
    Album.all.each do |album|
      if(inArea(album.ref_latitude, album.ref_longitude))
        PlaceAlbumInArea.create(:place_id => id, :album_id => album.id)
      end
    end
  end

  #Insert this place into existing areas it is located in to avoid having to refresh the areas.
  def addToAreas
    AreaPlace.delete parent_area_place_ids
    centerLat = centerLatitude
    centerLong = centerLongitude
    Place.areas.each do |area|
      if(area.inArea(centerLat, centerLong))
        AreaPlace.create(:area_id => area.id, :place_id => self.id)
      end
    end
  end

  #Returns true if the given point lies in the area
  #Does this by counting intersections
  def inArea lat, lon
    if(!inBounds(lat,lon))
      false
    else
      lastpoint = border_points.last
      y2 = 100
      x2 = 200
      a = (y2 - lat)/(x2 - lon)
      b = lat - a*lon
      icount = 0
      border_points_minus_removed.each_with_index do |point|
	if(intersect(lastpoint, point, a, b, lon, x2))
	  icount += 1
	end
	lastpoint = point
      end
      (icount % 2) == 1
    end
  end

  #New border points are not always sorted. 
  def sortBorderPoints
    border_points.sort { |a,b| a.local_index <=> b.local_index }
  end

  #Return true if the border points have changed
  def border_points_changed?
    changed = false
    border_points.each do |point|
      changed |= point.latitude_changed? || point.longitude_changed? || point.marked_for_destruction?
    end
    changed
  end

  #Returns the places in the surrounding 15km without title photos sorted by distance.
  #Uses unsanitized latitude and longitude since .order doesn't sanitize
  def places_nearby_without_title_photos radius=15
    Place.find_by_radius(centerLatitude,centerLongitude,radius).where("places.id != ?", id).where("places.name_status != 'unnamed' and places.id not in (select distinct photos.place_id from photos where photos.place_id is not null)").order("places.type != 'Mountain', power(places.latitude - #{centerLatitude.to_f},2)+power(places.longitude - #{centerLongitude.to_f},2)")
  end

  #Returns the places in the surrounding 15km without any photos sorted by distance.
  #Uses unsanitized latitude and longitude since .order doesn't sanitize
  def places_nearby_without_photos radius=15
    Place.find_by_radius(centerLatitude,centerLongitude,radius).where("places.id != ?", id).where("places.name_status != 'unnamed' and places.id not in (select distinct photos.place_id from photos where photos.place_id is not null) and places.id not in (select distinct place_id from place_photos)").order("places.type != 'Mountain', power(places.latitude - #{centerLatitude.to_f},2)+power(places.longitude - #{centerLongitude.to_f},2)")
  end

  def feet
    self.height.nil? ? nil : (self.height * 3.2808399).round
  end

  #Can call this function for objects that define latitude and longitude
  def distance object
    GeographyHelper.distance latitude, longitude, object.latitude, object.longitude
  end

  #Haversine Formula
  def dist lat2, lon2
    GeographyHelper.distance centerLatitude, centerLongitude, lat2, lon2
  end

  def direction lat2, lon2
    GeographyHelper.direction centerLatitude, centerLongitude, lat2, lon2
  end

  def sitemap_priority
    area.present? && area > 0 ? 0.7 : 0.5 
  end

  private

  #returns true if the point lies in the bounding box of the area
  def inBounds lat, lon
    lat <= max_latitude && lat >= min_latitude && lon <= max_longitude && lon >= min_longitude
  end

  #Returns true if the line point1-point2 intersects the line y=a1x+b1 
  def intersect point1, point2, a1, b1, x1, x2
    a2 = (point2.latitude - point1.latitude)/(point2.longitude-point1.longitude)
    b2 = point1.latitude - a2*point1.longitude
    x = (b2-b1)/(a1-a2)
    x3 = point1.longitude < point2.longitude ? point1.longitude : point2.longitude
    x4 = point1.longitude > point2.longitude ? point1.longitude : point2.longitude
    x >= x1 && x <= x2 && x >= x3 && x <= x4
  end

  #Returns border points that are not marked for destruction
  def border_points_minus_removed
    points = []
    border_points.each do |point|
      points << point if !point.marked_for_destruction?
    end
    points
  end

  #Returns an error if the area doesn't have enough border points
  def must_have_at_least_three_border_points_or_center_point 
    if (self.latitude.nil? || self.longitude.nil?) && border_points.length < 3
      errors.add(:latitude, "You must enter a center point or at least 3 border points")
    end
  end

  #No 2 point places can be less than 0.02
  #No 2 point places with the same name can be less than 20 km from each other
  def no_duplicate_places

    return if (self.latitude.nil? || self.longitude.nil?) && border_points.length < 3
    return unless name_changed? || self.id.nil? || self.latitude_changed? || self.longitude_changed?
    places = Place.find_by_radius(centerLatitude,centerLongitude,0.02,0)
    if(places.length > 1 || (places.length == 1 && places.first != self))
      errors.add(:latitude, "Must be at least 20 meters from other places")
    end

    Place.find_by_radius(centerLatitude, centerLongitude, 10, 0).each do |place|
      if place.id != self.id && place.name == self.name
        errors.add(:name, "There is already a #{self.class.to_s} with that name in this area")
      end
    end
  end

end
