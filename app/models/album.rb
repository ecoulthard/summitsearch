class Album < ActiveRecord::Base
  include Concerns::Viewable
  include Concerns::Visitable
  include GeographyHelper
  include PlaceLinkingHelper
  versioned
  cattr_reader :per_page
  @@per_page = 100

  belongs_to :user
  belongs_to :updater, :foreign_key => "update_id", :class_name => "User"
  belongs_to :place
  belongs_to :trip_report
  belongs_to :route
  has_one :topic, :class_name => "Forem::Topic"

  has_many :place_albums, :dependent => :destroy
  has_many :places_mentioned, :through => :place_albums, :source => :place

  has_many :place_albums_in_areas, :dependent => :destroy, :class_name => "PlaceAlbumInArea"
  has_many :areas, -> { order 'area' }, :through => :place_albums_in_areas, :source => :place

  has_many :photos, -> { order :time }
  has_many :comments, :through => :topic, :source => :posts, :class_name => "Forem::Post"

  has_many :route_albums, :dependent => :destroy
  has_many :routes_mentioned, :through => :route_albums, :source => :route

  validates :user_id, :presence => true
  validates_length_of :title, maximum: 128
  validates_length_of :description, maximum: 30720
 
  SORT_OPTIONS = {'title' => 'title', 'date_created' => 'created_at DESC', 'last_liked' => 'last_liked_at DESC NULLS LAST', 'last_commented' => 'last_comment_at DESC NULLS LAST', 'total_likes' => 'total_likes DESC NULLS LAST', 'total_comments' => 'total_comments DESC NULLS LAST'}
  DEFAULT_SORT = 'date_created'
  
  after_create :addToAreas
  before_save :trim_content
  before_update :set_links # Add links to places

  def to_param
    title.nil? ? "#{id}" : "#{id}-#{title.parameterize}"
  end

  def trim_content
    self.title.strip! unless self.title.nil?
    self.description.strip! unless self.description.nil?
  end

  # A summary string to use for autocomplete
  def autocomplete_summary
    summary = "Album: #{title}"
  end

#  #After creating an album credit the maker with some amount of access time
#  def addCreateContributionTime
#    user.add_content_contribution_time User::NEW_TRIP_CONTRIBUTION_AMOUNT
#  end

  def latitude
    ref_latitude
  end
  
  def longitude
    ref_longitude
  end

  #Called when a recommendation is added to the album.
  #Used to add contribution time if the album was recommended enough times.
  #recentGrantedAccessTime was only used to notify the user when they log in of the increased
  #access time. It was cleared after notification.
  def recommendationAdded
#    totalThumbsUp = self.views.where('rating > 0').sum(:rating)
#    if(totalThumbsUp == User::NEW_TRIP_2ND_CONTRIBUTION_CUTOFF)
#      user.add_content_contribution_time User::NEW_TRIP_2ND_CONTRIBUTION_AMOUNT
#      user.recentGrantedAccessTime += User::NEW_TRIP_2ND_CONTRIBUTION_AMOUNT
#      user.save
#    elsif(totalThumbsUp == User::NEW_TRIP_3RD_CONTRIBUTION_CUTOFF)
#      user.add_content_contribution_time User::NEW_TRIP_3RD_CONTRIBUTION_AMOUNT
#      user.recentGrantedAccessTime += User::NEW_TRIP_3RD_CONTRIBUTION_AMOUNT
#      user.save
#    end
  end

  #My list function for model index pages.
  #Lists all models with title >= lower and <= upper
  def self.list sort=DEFAULT_SORT, lower=nil, upper=nil
    if !lower.nil? && !upper.nil? && sort=="Title" #Grab alphabetical interval of albums
      where("LEFT(title,:length) >= :lower AND LEFT(title,:length) <= :upper", {:lower => lower, :upper => upper, :length => lower.length }).order(SORT_OPTIONS[sort])
    else
      where('deleted IS NULL OR NOT deleted').order(SORT_OPTIONS[sort])
    end
  end

  #Returns which forum to use for a topic about this album.
  def forum
    area = areas.where("forum_id IS NOT NULL").order(:area).first
    area.nil? ? Forem::Forum.find_by_name("Other Regions") : area.forum
  end

  def set_links
    PlaceAlbum.delete place_album_ids
    RouteAlbum.delete route_album_ids
    self.place_id = nil
    return if deleted
    set_places title, description
  end

  private

  #Insert this album into existing areas it is located in to avoid having to refresh the area page.
  def addToAreas
    PlaceAlbumInArea.delete place_albums_in_area_ids
    Place.areas.each do |area|
      if(area.inArea(self.ref_latitude, self.ref_longitude) && PlaceAlbumInArea.where(:place_id => area.id, :album_id => self.id).empty?)
        PlaceAlbumInArea.create(:place_id => area.id, :album_id => self.id)
      end
    end
  end

end
