require "mini_magick"
require "exifr/jpeg"

class Photo < ApplicationRecord
  include Viewable
  include Visitable
  include GeographyHelper
  include PlaceLinkingHelper
  include ActiveModel::Dirty
  has_paper_trail
  cattr_reader :per_page
  @@per_page = 200
  belongs_to :user, optional: true
  belongs_to :updater, :foreign_key => "update_id", :class_name => "User", optional: true
  #belongs_to :place
  belongs_to :trip_report, optional: true
  belongs_to :route, optional: true
  belongs_to :album, optional: true
  belongs_to :parent_topic, :foreign_key => "topic_id", :class_name => "Forem::Topic", optional: true
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

  has_many :place_photos, :dependent => :destroy
  has_many :places, through: :place_photos
  has_many :title_place_photos, -> { where(:in_title => true ) }, class_name: "PlacePhoto"
  has_many :title_places, through: :title_place_photos, source: :place
  has_many :place_mentioned_photos, -> { where(:in_title => false ) }, class_name: "PlacePhoto"
  has_many :places_mentioned, through: :place_mentioned_photos, source: :place

  has_many :place_photos_in_areas, :dependent => :destroy, :class_name => "PlacePhotoInArea"
  #Areas that the photo was taken inside
  has_many :areas, -> { order 'area'}, :through => :place_photos_in_areas, :source => :place
  
  has_many :route_photos, :dependent => :destroy
  has_many :routes_mentioned, :through => :route_photos, :source => :route

  has_one_attached :photo do |attachable|
    attachable.variant :original, resize_to_limit: [20000, 1500], saver: { quality: 75 }
    attachable.variant :medium, resize_to_limit: [3000, 650], saver: { quality: 75 }
    attachable.variant :small, resize_to_limit: [800, 300], saver: { quality: 75 }
    attachable.variant :thumb, resize_to_limit: [150, 150], saver: { quality: 75 }
    attachable.variant :long_thumb, resize_to_limit: [500, 100], saver: { quality: 75 }
    attachable.variant :tiny, resize_to_limit: [80, 80], saver: { quality: 75 }
  end

  validates :photo, presence: true
  validate :validate_photo_attachment
  
  validates :user_id, :presence => true
  validates_length_of :title, maximum: 128
  validates_length_of :caption, maximum: 30720
  validates_length_of :vantage, maximum: 30720
  validates_length_of :description, maximum: 30720

  validate :no_duplicate_photos, :on => :create

  before_validation :sync_attachment_attributes
  before_create :undeleteAlbum #Albums without photos are considered deleted
  before_save :trim_content
  after_create :save #save twice when created in order to add links and other things
  after_create :touch_place_route
  before_save :setFieldsIfBlank
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

  PHOTO_STYLES = {
    original: { width: 20000, height: 1500 },
    medium: { width: 3000, height: 650 },
    small: { width: 800, height: 300 },
    thumb: { width: 150, height: 150 },
    long_thumb: { width: 500, height: 100 },
    tiny: { width: 80, height: 80 }
  }.freeze

  def validate_photo_attachment
    return unless photo.attached? && photo.blob.present?

    if photo.blob.byte_size > 50.megabytes
      errors.add(:photo, "must be less than 50MB")
    end

    acceptable_types = ["image/jpeg", "image/pjpeg", "image/png", "image/gif"]
    unless acceptable_types.include?(photo.blob.content_type)
      errors.add(:photo, "must be a JPEG, PNG, or GIF")
    end
  end

  def sync_attachment_attributes
    return unless photo.attached? && photo.blob.present?

    self.photo_file_name = photo.blob.filename.to_s if respond_to?(:photo_file_name=)
    self.photo_content_type = photo.blob.content_type if respond_to?(:photo_content_type=)
    self.photo_file_size = photo.blob.byte_size if respond_to?(:photo_file_size=)
  end

  def ratio
    #geo = Paperclip::Geometry.from_file(photo(:original))
    #geo.width/geo.height
    photo_width.to_f/photo_height.to_f
  end

  def is_panorama?
    return false unless photo.attached?
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
    PHOTO_STYLES[:long_thumb][:width]
  end

  def max_long_thumb_height
    PHOTO_STYLES[:long_thumb][:height]
  end

  def max_long_thumb_ratio
    max_long_thumb_width/max_long_thumb_height
  end

  def long_thumb_width
    return 0 unless photo.attached?
    #ratio = photo_width.to_f/photo_height.to_f
    #ratio = geo.width/geo.height
    ratio > max_long_thumb_ratio ? max_long_thumb_width : (max_long_thumb_height * ratio).to_i
  end

  def long_thumb_height
    return 0 unless photo.attached?
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
    PHOTO_STYLES[:small][:width]
  end

  def max_small_height
    PHOTO_STYLES[:small][:height]
  end

  def max_small_ratio
    max_small_width/max_small_height
  end

  def small_width
    return 0 unless photo.attached?
    ratio = photo_width.to_f/photo_height.to_f
    ratio > max_small_ratio ? max_small_width : (max_small_height * ratio).to_i
  end

  def small_height
    return 0 unless photo.attached?
    ratio = photo_width.to_f/photo_height.to_f
    ratio > max_small_ratio ? (max_small_width / ratio).to_i : max_small_height
  end

  #Grabbes the geometry/exif data if available and set fields that are blank or have changed.
  def setFieldsIfBlank
    return unless photo.attached? && photo.blob.present?
    
    sync_attachment_attributes
    
    changed_fields = {}
    
    begin
      with_attached_photo_file do |photo_file_path|
        if File.exist?(photo_file_path)
          exif_img = nil
          if photo.blob.content_type.to_s =~ /jpe?g/i
            begin
              exif_img = EXIFR::JPEG.new(photo_file_path)
            rescue => e
            end
          end

          width = nil
          height = nil
          if exif_img && exif_img.width && exif_img.height
            width = exif_img.width
            height = exif_img.height
          elsif photo.blob.metadata[:width] && photo.blob.metadata[:height]
            width = photo.blob.metadata[:width]
            height = photo.blob.metadata[:height]
          else
            begin
              image = MiniMagick::Image.open(photo_file_path)
              width = image.width
              height = image.height
            rescue => e
            end

            if width.nil? || height.nil?
              raw_w, raw_h = extract_dimensions_from_header(photo_file_path)
              width ||= raw_w
              height ||= raw_h
            end
          end

          if (self.photo_width.nil? || self.photo_width.blank?) && width.present?
            self.photo_width = changed_fields[:photo_width] = width
          end
          if (self.photo_height.nil? || self.photo_height.blank?) && height.present?
            self.photo_height = changed_fields[:photo_height] = height
          end

          if exif_img
            if (self.time.nil? || self.time.blank?) && !exif_img.date_time_original.nil?
              self.time = changed_fields[:time] = exif_img.date_time_original
            end
            if (self.latitude.nil? || self.latitude.blank?) && !exif_img.gps_latitude.nil?
              lat = exif_img.gps_latitude
              sign = exif_img.gps_latitude_ref == "N" ? 1 : -1
              self.latitude = changed_fields[:latitude] = sign*lat[0].to_f + sign*lat[1].to_f/60 + sign*lat[2].to_f/3600
            end
            if (self.longitude.nil? || self.longitude.blank?) && !exif_img.gps_longitude.nil?
              lon = exif_img.gps_longitude
              sign = exif_img.gps_longitude_ref == "E" ? 1 : -1
              self.longitude = changed_fields[:longitude] = sign*lon[0].to_f + sign*lon[1].to_f/60 + sign*lon[2].to_f/3600
            end
            if (self.height.nil? || self.height.blank?) && !exif_img.gps_altitude.nil?
              self.height = changed_fields[:height] = exif_img.gps_altitude
            end
          end
        end
      end
    rescue => e
    end

    #If GPS coordinates are blank and previous photo in this trip or album has some then copy them.
    if !neighbourPhoto.nil? && !neighbourPhoto.latitude.nil? && (self.latitude.nil? || self.latitude.blank?) && (self.longitude.nil? || self.longitude.blank?) && (self.height.nil? || self.height.blank?)
      self.latitude = changed_fields[:latitude] = neighbourPhoto.latitude
      self.longitude = changed_fields[:longitude] = neighbourPhoto.longitude
      self.height = changed_fields[:height] = neighbourPhoto.height
    end
    update_columns(changed_fields) if changed_fields.count > 0 && persisted?
  end

  def with_attached_photo_file
    if attachment_changes["photo"].present?
      change = attachment_changes["photo"]
      attachable = change.attachable
      if attachable.respond_to?(:tempfile) && attachable.tempfile.respond_to?(:path)
        yield attachable.tempfile.path
      elsif attachable.respond_to?(:path) && File.exist?(attachable.path.to_s)
        yield attachable.path
      elsif attachable.is_a?(Hash) && attachable[:io].present?
        io = attachable[:io]
        if io.respond_to?(:path) && File.exist?(io.path.to_s)
          yield io.path
        else
          ext = File.extname(photo.blob&.filename.to_s)
          temp = Tempfile.new(["photo_blob", ext])
          begin
            temp.binmode
            io.rewind if io.respond_to?(:rewind)
            temp.write(io.read)
            io.rewind if io.respond_to?(:rewind)
            temp.flush
            temp.rewind
            yield temp.path
          ensure
            temp.close!
          end
        end
      elsif photo.attached? && photo.blob&.persisted?
        photo.blob.open { |f| yield f.path }
      end
    elsif photo.attached? && photo.blob.present?
      photo.blob.open { |f| yield f.path }
    end
  end

  def extract_dimensions_from_header(path)
    return [nil, nil] unless File.exist?(path.to_s)
    header = File.binread(path, 32)
    return [nil, nil] if header.nil? || header.length < 10

    if header[0, 8] == "\x89PNG\r\n\x1a\n".b && header.length >= 24
      header[16, 8].unpack("NN")
    elsif header[0, 3] == "GIF".b && header.length >= 10
      header[6, 4].unpack("vv")
    else
      [nil, nil]
    end
  end

  #Returns the previous photo or next photo of this photo in the trip report or album
  def neighbourPhoto
    if trip_report_id.present? && respond_to?(:trip_report) && trip_report.present?
      index = trip_report.photos.find_index(self)
      if index.nil?
        nil
      elsif index > 0
        trip_report.photos[index-1]
      elsif index < trip_report.photos.length-1
        trip_report.photos[index+1]
      end
    elsif album_id.present? && respond_to?(:album) && album.present?
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
    lat.nil? ? nil : lat.round(6)
  end
  
  def lon_for_map
    lon = self.longitude.nil? ? self.ref_longitude : self.longitude
    lon.nil? ? nil : lon.round(6)
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
    if album_id.present? && respond_to?(:album) && album.present?
      album.deleted = false
      album.save
    end
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
      if trip_report.user_id == self.user_id #Found definite match exit with success
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

    return if lat.nil? || lon.nil?

    PlacePhotoInArea.delete place_photos_in_area_ids
    Place.areas.each do |area|
      if(area.inArea(lat, lon) && PlacePhotoInArea.where(:place_id => area.id, :photo_id => self.id).empty?)
        PlacePhotoInArea.create(:place_id => area.id, :photo_id => self.id)
      end
    end
  end

  #No 2 photos with the same file_name, time and user can be submitted unless they both have titles that differ
  def no_duplicate_photos
    sync_attachment_attributes if photo.attached? && photo.blob.present?
    filename = self.photo_file_name || (photo.attached? && photo.blob ? photo.blob.filename.to_s : nil)
    filesize = self.photo_file_size || (photo.attached? && photo.blob ? photo.blob.byte_size : nil)
    return if filename.nil? || self.time.nil?

    Photo.where("user_id = ? AND photo_file_name = ? AND time = ? AND photo_file_size = ?", self.user_id, filename, self.time, filesize).each do |photo_record|
      if((self.id.nil? ) && ((self.title.blank? && self.caption.blank?) || self.title == photo_record.title))
        errors.add(:photo_file_name, "There is already a photo submitted by you with the same filename and time. To submit the same photo twice you need to at least give it a unique filename.")
      end
    end
  end


end
