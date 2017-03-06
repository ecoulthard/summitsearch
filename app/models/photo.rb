class Photo < ActiveRecord::Base
  include Concerns::Viewable
  include Concerns::Visitable
  include GeographyHelper
  include PlaceLinkingHelper
  include ActiveModel::Dirty
  versioned
  cattr_reader :per_page
  @@per_page = 200
  belongs_to :user
  belongs_to :updater, :foreign_key => "update_id", :class_name => "User"
  belongs_to :place
  belongs_to :trip_report
  belongs_to :route
  belongs_to :album
  belongs_to :parent_topic, :foreign_key => "topic_id", :class_name => "Forem::Topic"
  has_one :topic, :class_name => "Forem::Topic"

  has_many :comments, :through => :topic, :source => :posts, :class_name => "Forem::Post"

  #Gets all the place visits from the photos place to the photo or vice versa
  #We join visits to the ip_address that caused the visit
  #Then we join on visits again only these visits are for the place.
  #We filter out visits from the creator of the photo.
  def place_visits
    visits.joins(:ip_address)
    .joins("INNER JOIN visits photo_place_visits ON photo_place_visits.ip_address_id = ip_addresses.id")
    .where("ip_addresses.user_id IS NULL OR ip_addresses.user_id <> ?", user_id)
    .where("photo_place_visits.visitable_type = 'Place' AND photo_place_visits.visitable_id = ?", place_id)
  end


  has_many :place_photos_in_areas, :dependent => :destroy, :class_name => "PlacePhotoInArea"
  #Areas that the photo was taken inside
  has_many :areas, -> { order 'area'}, :through => :place_photos_in_areas, :source => :place
  has_many :place_photos, :dependent => :destroy
  has_many :places_mentioned, :through => :place_photos, :source => :place
  
  has_many :route_photos, :dependent => :destroy
  has_many :routes_mentioned, :through => :route_photos, :source => :route

  has_attached_file :photo, :styles => { :original => "20000x1500>", :medium => "3000x650>", :small => "800x300>", :thumb => "150x150>", :long_thumb => "500x100", :tiny => "80x80>" }, :url => "/system/photos/:attachment/:id/:style/:basename.:extension",  
  :path => ":rails_root/public/system/photos/:attachment/:id/:style/:basename.:extension", :convert_options => { :all => "-quality 75"}

  validates_attachment_presence :photo
  validates_attachment_size :photo, :less_than => 50.megabytes
  validates_attachment_content_type :photo, :content_type => ['image/jpeg','image/pjpeg', 'image/png', 'image/gif']
  
  validates :user_id, :ref_latitude, :ref_longitude, :ref_title, :ref_content, :presence => true
  validates :ref_latitude, :numericality => {:greater_than_or_equal_to => -90, :less_than_or_equal_to => 90}
  validates :ref_longitude, :numericality => {:greater_than_or_equal_to => -180, :less_than_or_equal_to => 180}
  validates_length_of :title, maximum: 128
  validates_length_of :caption, maximum: 30720
  validates_length_of :vantage, maximum: 30720
  validates_length_of :description, maximum: 30720

  validate :no_duplicate_photos, :on => :create

  before_create :undeleteAlbum #Albums without photos are considered deleted
  before_save :trim_content
  after_create :save #save twice when created in order to add links and other things
  after_create :touch_place_route
  after_save :setFieldsIfBlank
  #after_create :addCreateContributionTime
  before_update :set_links # Add links to places,trip reports... etc
  after_update :addToAreas

  SORT_OPTIONS = {'title' => 'title', 'date_created' => 'created_at DESC', 'last_liked' => 'last_liked_at DESC NULLS LAST', 'last_commented' => 'last_comment_at DESC NULLS LAST', 'total_likes' => 'total_likes DESC NULLS LAST', 'total_comments' => 'total_comments DESC NULLS LAST'}
  DEFAULT_SORT = 'date_created'

=begin
  searchable do
    text :title#, :boost => 3
    text :caption
    text :description
    integer :importance
  end
=end
  
  #Search friendly parameters
  def to_param
    "#{id}-#{title.nil? ? '' : title.parameterize}-photo"
  end

  # Returns content to put in the html img alt attribute
  def alt
    self.title.blank? ? self.caption : self.title
  end

  def trim_content
    self.title.strip! unless self.title.nil?
    self.caption.strip! unless self.caption.nil?
  end

  # A summary string to use for autocomplete
  def autocomplete_summary
    summary = "Photo: #{title}"
  end

  def touch_place_route
    place.save unless self.place_id.nil?
    route.save unless self.route_id.nil?
  end

  def ratio
    #geo = Paperclip::Geometry.from_file(photo(:original))
    #geo.width/geo.height
    photo_width.to_f/photo_height.to_f
  end

  def is_panorama?
    return false unless photo.exists?
    #geo = Paperclip::Geometry.from_file(photo(:original))
    #ratio = geo.width/geo.height
    #ratio = photo_width.to_f/photo_height.to_f
    ratio > 2.0 # If ratio greater than 200:100 then it is a panorama
  end

  #returns what to set the width attribute of a thumbDiv
  def thumb_div_width
    long_thumb_width > min_long_thumb_width ? long_thumb_width : min_long_thumb_width   
  end
  
  #This is max_height * 1.5
  def min_long_thumb_width
   (max_long_thumb_height*(4.0/3.0)).to_i
  end

  def max_long_thumb_width
    photo.styles[:long_thumb].geometry.to_i
  end

  def max_long_thumb_height
    geo=photo.styles[:long_thumb].geometry
    geo[geo.index('x')+1..-1].to_i
  end

  def max_long_thumb_ratio
    max_long_thumb_width/max_long_thumb_height
  end

  def long_thumb_width
    return 0 unless photo.exists?
    #ratio = photo_width.to_f/photo_height.to_f
    #ratio = geo.width/geo.height
    ratio > max_long_thumb_ratio ? max_long_thumb_width : (max_long_thumb_height * ratio).to_i
  end

  def long_thumb_height
    return 0 unless photo.exists?
    #ratio = photo_width.to_f/photo_height.to_f
    ratio > max_long_thumb_ratio ? (max_long_thumb_width / ratio).to_i : max_long_thumb_height
  end

  #returns what to set the width attribute of a smallDiv
  def small_div_width
    small_width > min_small_width ? small_width : min_small_width   
  end
  
  #This is max_height * 1.5
  def min_small_width
   (max_small_height*(4.0/3.0)).to_i
  end

  def max_small_width
    photo.styles[:small].geometry.to_i
  end

  def max_small_height
    geo=photo.styles[:small].geometry
    geo[geo.index('x')+1..-1].to_i
  end

  def max_small_ratio
    max_small_width/max_small_height
  end

  def small_width
    return 0 unless photo.exists?
    ratio = photo_width.to_f/photo_height.to_f
    ratio > max_small_ratio ? max_small_width : (max_small_height * ratio).to_i
  end

  def small_height
    return 0 unless photo.exists?
    ratio = photo_width.to_f/photo_height.to_f
    ratio > max_small_ratio ? (max_small_width / ratio).to_i : max_small_height
  end

  #Grabbes the geometry/exif data if available and set fields that are blank or have changed.
  def setFieldsIfBlank
    return if photo.nil?
    photo_file = photo.queued_for_write[:original].nil? ? photo.path : photo.queued_for_write[:original].path
    return unless File.exists? photo_file
    changed_fields = {}
    #geo = Paperclip::Geometry.from_file(photo)
    #photo_path = self.photo(:original)
    exif_img = EXIFR::JPEG.new(photo_file)
    geo = Paperclip::Geometry.from_file(photo_file)
    if (self.photo_width.nil? || self.photo_width.blank?) && !geo.width.nil?
      self.photo_width = changed_fields[:photo_width] = geo.width
    end
    if (self.photo_height.nil? || self.photo_height.blank?) && !geo.height.nil?
      self.photo_height = changed_fields[:photo_height] = geo.height
    end
    if (self.time.nil? || self.time.blank?) && !exif_img.date_time_original.nil?
      self.time = changed_fields[:time] = exif_img.date_time_original
    end
    if (self.latitude.nil? || self.latitude.blank?) && !exif_img.gps_latitude.nil?
      lat = exif_img.gps_latitude
      sign = exif_img.gps_latitude_ref == "N" ? 1 : -1
      self.latitude = changed_fields[:latitude] = sign*lat[0].to_f + sign*lat[1].to_f/60 + sign*lat[2].to_f/3600
      changed = true
    end
    if (self.longitude.nil? || self.longitude.blank?) && !exif_img.gps_longitude.nil?
      lon = exif_img.gps_longitude
      sign = exif_img.gps_longitude_ref == "E" ? 1 : -1
      self.longitude = changed_fields[:longitude] = sign*lon[0].to_f + sign*lon[1].to_f/60 + sign*lon[2].to_f/3600
      changed = true
    end
    if (self.height.nil? || self.height.blank?) && !exif_img.gps_altitude.nil?
      self.height = changed_fields[:height] = exif_img.gps_altitude
      changed = true
    end
    #If GPS coordinates are blank and previous photo in this trip or album has some then copy them.
    if !neighbourPhoto.nil? && !neighbourPhoto.latitude.nil? && (self.latitude.nil? || self.latitude.blank?) && (self.longitude.nil? || self.longitude.blank?) && (self.height.nil? || self.height.blank?)
      self.latitude = changed_fields[:latitude] = neighbourPhoto.latitude
      self.longitude = changed_fields[:longitude] = neighbourPhoto.longitude
      self.height = changed_fields[:height] = neighbourPhoto.height
    end
    update_columns(changed_fields) if changed_fields.count > 0 && persisted?
  end

  #Returns the previous photo or next photo of this photo in the trip report or album
  def neighbourPhoto
    if trip_report.present?
      index = trip_report.photos.find_index(self)
      if index.nil?
        nil
      elsif index > 0
        trip_report.photos[index-1]
      elsif index < trip_report.photos.length-1
        trip_report.photos[index+1]
      end
    elsif album.present?
      index = album.photos.find_index(self)
      if index.nil?
        nil
      elsif index > 0
        album.photos[index-1]
      elsif index < album.photos.length-1
        album.photos[index+1]
      end
    else
      nil
    end
  end

  #Since lat/lon may not always be set we return ref lat/lon in that case
  def lat_for_map
    lat = self.latitude.nil? ? self.ref_latitude : self.latitude
    lat.round(6)
  end
  
  def lon_for_map
    lon = self.longitude.nil? ? self.ref_longitude : self.longitude
    lon.round(6)
  end

#  #After creating a photo credit the maker with some amount of access time
#  def addCreateContributionTime
#    user.add_content_contribution_time User::NEW_PHOTO_CONTRIBUTION_AMOUNT
#  end

  #Called when a recommendation is added to the photo.
  #Used to add contribution time if the photo was recommended enough times.
  #recentGrantedAccessTime was used to notify the user when they log in of the increased
  #access time. It was cleared after notification.
  def recommendationAdded
#    totalThumbsUp = self.views.where('rating > 0').sum(:rating)
#    if(totalThumbsUp == User::NEW_PHOTO_2ND_CONTRIBUTION_CUTOFF)
#      user.add_content_contribution_time User::NEW_PHOTO_2ND_CONTRIBUTION_AMOUNT
#      user.recentGrantedAccessTime += User::NEW_PHOTO_2ND_CONTRIBUTION_AMOUNT
#      user.save
#    elsif(totalThumbsUp == User::NEW_PHOTO_3RD_CONTRIBUTION_CUTOFF)
#      user.add_content_contribution_time User::NEW_PHOTO_3RD_CONTRIBUTION_AMOUNT
#      user.recentGrantedAccessTime += User::NEW_PHOTO_3RD_CONTRIBUTION_AMOUNT
#      user.save
#    end
  end

  #My list function for photo index pages
  def self.list sort=DEFAULT_SORT
    order(SORT_OPTIONS[sort])
  end

  #My search function for nearby photos
  #Title or caption must be like search text
  def self.search_nearby lat, lon, radius, search='', user_id=nil, trip_report_id=nil, topic_id=nil, sort=DEFAULT_SORT
    photos = Photo.find_by_radius lat,lon,radius
    photos = photos.where("user_id = ?", user_id) unless user_id.nil?
    photos = photos.where("trip_report_id = ?", trip_report_id) unless trip_report_id.nil?
    photos = photos.where("topic_id = ?", topic_id) unless topic_id.nil?
    if search != ""
      photos.where("(title LIKE ? OR caption LIKE ?)", "%#{search}%", "%#{search}%").order(SORT_OPTIONS[sort])
    elsif trip_report_id.blank? && topic_id.blank?
      photos.where("title IS NOT NULL AND title !=''").order(SORT_OPTIONS[sort])
    else
      photos
    end
  end

  #will find all photo that match the time range give or take an hour
  def self.find_by_time start_time, end_time
     start_time_minus_one_hour = (start_time.to_time - 30.minutes).to_datetime
     end_time_plus_one_hour = (end_time.to_time + 30.minutes).to_datetime
     Photo.where(":start_time <= time and :end_time >= time", {:start_time => start_time_minus_one_hour, :end_time => end_time_plus_one_hour})
  end

  #Find all the photos in the given location and radius
  def self.find_by_radius lat, lon, radius
    maxLat = GeographyHelper.maxLatitude lat, radius
    minLat = GeographyHelper.minLatitude lat, radius
    maxLon = GeographyHelper.maxLongitude lat, lon, radius
    minLon = GeographyHelper.minLongitude lat, lon, radius
    Photo.where("(latitude > :minLat and latitude < :maxLat and longitude > :minLon and longitude < :maxLon) OR (ref_latitude > :minLat and ref_latitude < :maxLat and ref_longitude > :minLon and ref_longitude < :maxLon)", {:minLat => minLat, :maxLat => maxLat, :minLon => minLon, :maxLon => maxLon})
  end

  def undeleteAlbum #Albums without photos are considered deleted
    album.deleted = false if album_id
    album.save if album_id
  end

  #Returns which forum to use for a topic about this photo.
  def forum
    area = areas.where("forum_id IS NOT NULL").order(:area).first
    area.nil? ? Forem::Forum.find_by_name("Other Regions") : area.forum
  end

  #Adds links between the photo and places,routes or trip reports
  #Since it uses ids it must be called after photo is saved
  def set_links
    return unless self.title_changed? || self.caption_changed?
    PlacePhoto.delete place_photo_ids
    RoutePhoto.delete route_photo_ids
    self.place_id = nil
    set_places title, caption
    set_trip_report
  end

  #Finds a trip report to attach the photo to. Looks for trip reports taken place at the same time
  def set_trip_report 
    return if self.time.nil? || self.time.blank?
    trip_reports = TripReport.find_by_time(self.time)
    trip_reports.each do |trip_report|
      if trip_report.user == self.user #Found definite match exit with success
	      self.trip_report_id = trip_report.id
	      break
      end
    end
  end

  private

  #Insert this photo into existing places it is located in to avoid having to refresh the place page.
  def addToAreas
    #return unless self.ref_latitude_changed? || self.ref_longitude_changed? || self.latitude_changed? || self.longitude_changed?
    lat = self.latitude.nil? ? self.ref_latitude : self.latitude
    lon = self.longitude.nil? ? self.ref_longitude : self.longitude
    PlacePhotoInArea.delete place_photos_in_area_ids
    Place.areas.each do |area|
      if(area.inArea(lat, lon) && PlacePhotoInArea.where(:place_id => area.id, :photo_id => self.id).empty?)
        PlacePhotoInArea.create(:place_id => area.id, :photo_id => self.id)
      end
    end
  end

  #No 2 photos with the same file_name, time and user can be submitted unless they both have titles that differ
  def no_duplicate_photos
    Photo.where("user_id = ? AND photo_file_name = ? AND time = ? AND photo_file_size = ?", self.user_id, self.photo_file_name, self.time, self.photo_file_size).each do |photo|
      if((self.id.nil? ) && ((self.title.blank? && self.caption.blank?) || self.title == photo.title))
        errors.add(:photo_file_name, "There is already a photo submitted by you with the same filename and time. To submit the same photo twice you need to at least give it a unique title.")
      end
    end
  end


end
