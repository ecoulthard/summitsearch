class Mountain < Place
  has_one :detail, class_name: "MountainDetail", inverse_of: :mountain, dependent: :destroy, autosave: true
  has_one :parent_mountain, through: :detail

  has_many :ascents, :dependent => :destroy, :foreign_key => :place_id
  has_many :subpeak_ascents, :through => :mountains, :class_name => "Ascent", :source => :ascents
  
  accepts_nested_attributes_for :ascents, :allow_destroy => true, :limit => 50

  delegate :parent_mountain_id, :parent_mountain_id=, to: :lazily_built_detail
  delegate :dist_to_parent, :dist_to_parent=, to: :lazily_built_detail
  delegate :height_and_isolation, :height_and_isolation=, to: :lazily_built_detail
  delegate :prominence, :prominence=, to: :lazily_built_detail
  delegate :average_slope, :average_slope=, to: :lazily_built_detail
  delegate :steepest_slope, :steepest_slope=, to: :lazily_built_detail
  delegate :border_latitude_steepest_slope, :border_latitude_steepest_slope=, to: :lazily_built_detail
  delegate :border_longitude_steepest_slope, :border_longitude_steepest_slope=, to: :lazily_built_detail
 
  scope :order_by_isolation, -> { joins(:detail).merge(MountainDetail.order_by_isolation) }

  SORT_OPTIONS = {'height' => 'height DESC', 'isolation' => 'dist_to_parent DESC', 'height_and_isolation' => 'height_and_isolation DESC', 'name' => 'name', 'date_created' => 'created_at DESC'}
  DEFAULT_SORT = 'height_and_isolation'
  MARKER_ICON = 'mountains.png'
  MARKER_SHADOW = 'mountains.shadow.png'
  MARKER_ICON_SMALL = 'mountains_small.png'
  MARKER_SHADOW_SMALL = 'mountains_small.shadow.png'
  MARKER_ICON_CAMERA = 'mountains_camera.png'
  MARKER_ICON_GOV_GOOGLE = 'mountains_gov_google.png'

  #Words or abbr that almost for sure mean they are searching for a mountain. Spaces are important. mtn must go before mt since mtn contains mt.
  SEARCH_KEY_WORDS = [" mountain", "mount ", " ridge", " peak", " mtn.", " mtn", " pk.", " pk", "mt. ", "mt ", " mt"]
  
  self.before_name_article_accept_strings.clear()
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(the lake)
  self.article_trim_strings += %w(peak mountain mount)
  #mountain must go before mount so that we are not left with "ain" in the name

  before_save :set_parent_mountain # see function
  before_save :set_height_and_isolation
  before_save :set_importance # see function
  after_save :refresh_nearby_mountains

  def shortname
    self.name.gsub(' Mountain', '').gsub('Mount ', '').gsub(' Peak', '')
  end

  #When people refer to a mountain they can use Mount Name, Name Mountain, Mt. Name, Name mtn ...etc
  def aliases
    myAliases = ""
    if ['Mount ',' Mountain',' Peak'].any? {|word| self.name.include?(word)}
      short = shortname
      myAliases = "#{short} Mountain, Mount #{short}, Mt. #{short}, Mt #{short}, #{shortname} mt, #{shortname} mtn, #{short} mtn., #{short} Peak" 
    end
    myAliases
  end

  def highest_subpeak_height
    mountains.maximum(:height)
  end 

  def highest_subpeak_feet
    (highest_subpeak_height * 3.2808399).round
  end

  def highest_subpeak
    mountains.where("height = ?", highest_subpeak_height).first
  end

  def ascents_including_subpeaks
    ascents.includes(:route).includes(:people) + subpeak_ascents.includes(:route).includes(:people).includes(:mountain)
  end

  def set_height_and_isolation
    return if self.height.nil?
    set_parent_mountain if self.dist_to_parent.nil?
    self.height_and_isolation = self.dist_to_parent * self.height * self.height / 1000
  end

  def set_importance
    self.importance = (unsorted_photos.count + 1) * Math.sqrt(photo_appearances.count+2) * (trip_reports.count + 1) * Math.sqrt(height_and_isolation || 0)
  end

  def set_parent_mountain
    return if self.height.nil?
    
    #Keep doing increasing radius searches until we find higher mountains if this mountain is new
    #or its parent is no longer higher and thus disqualified as a parent mountain.
    if self.id.nil? || self.parent_mountain_id.nil? || self.parent_mountain.nil? || self.parent_mountain.height < self.height
      self.parent_mountain_id = nil
      self.dist_to_parent = 100000
      [30,100,1000,100000].each do |radius|
        self.set_parent_mountain_by_radius radius
        break if dist_to_parent < 100000 #if found a parent return. Else expand radius and keep looking
      end
    #This mountain is being refreshed because another closer mountain may be its parent now
    elsif self.height_changed? || self.latitude_changed? || self.longitude_changed?
      self.set_parent_mountain_by_radius self.dist_to_parent
    end
  end

  #Searches for the nearest higher mountain in a given radius and sets that as the parent mountain
  #Sets distance to parent mountain as well
  def set_parent_mountain_by_radius radius
      Place.find_by_radius(centerLatitude, centerLongitude, radius, (height||0)+1).where("type = 'Mountain'").each do |mountain|
        distance = dist(mountain.centerLatitude, mountain.centerLongitude) 
        if distance < dist_to_parent && self != mountain
          self.dist_to_parent = distance
	  self.parent_mountain_id = mountain.id
	  self.parent_mountain = mountain
	  self.set_height_and_isolation
	end
      end 
  end


  #My list function for mountain pages. Over rides the place search to make mountains starting
  #with "Mount" to not be necessarily considered to match starts_with('M')
  def self.list sort=DEFAULT_SORT, lower=nil, upper=nil
    if !lower.nil? && !upper.nil? && sort=="Name" #Grab alphabetical interval of places
      joins(:detail).where("(name NOT LIKE 'Mount %' AND LEFT(name,:length) >= :lower AND LEFT(name,:length) <= :upper) OR (name LIKE 'Mount %' AND LEFT(SUBSTR(name,7),:length) >= :lower AND LEFT(SUBSTR(name,7),:length) <= :upper)", {:lower => lower, :upper => upper, :length => lower.length }).order("CASE WHEN name NOT LIKE 'Mount %' THEN name ELSE SUBSTR(name,7) END")
    else
      joins(:detail).order(SORT_OPTIONS[sort])
    end
  end

  #Look for mountains within radius to parent or 30km whichever is higher.
  #If this mountain is higher than a mountain in this radius and closer than its parent
  #then change that mountains parent to be this mountain and update its dist_to_parent 
  def refresh_nearby_mountains
    return unless self.height_changed? || self.latitude_changed? || self.longitude_changed?
    Mountain.find_by_radius(self.latitude,self.longitude,self.dist_to_parent + 20).where("type = 'Mountain'").each do |mountain|
      next if mountain.height.nil? || mountain.dist_to_parent.nil?
      if mountain.height < self.height && self != mountain && dist(mountain.latitude, mountain.longitude) < mountain.dist_to_parent
        mountain.parent_mountain_id = self.id
	mountain.dist_to_parent = dist(mountain.latitude, mountain.longitude)
	mountain.set_height_and_isolation
        mountain.save
      end
    end
  end

  def lazily_built_detail
    detail || build_detail
  end

  #Doesn't work. Causes the mountain to not save.
  #Got this and other code that does work from 
  #http://belighted.com/en/blog/implementing-multiple-table-inheritance-in-rails
  #def changed_attributes
  #  super.merge(lazily_built_detail.changed_attributes)
  #end
end
