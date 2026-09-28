class Album < ApplicationRecord
  include Viewable
  include Visitable
  include GeographyHelper
  include PlaceLinkingHelper
  has_paper_trail
  cattr_reader :per_page
  @@per_page = 100

  belongs_to :user
  belongs_to :updater, foreign_key: "update_id", class_name: "User", optional: true
  belongs_to :place, optional: true
  belongs_to :route, optional: true
  has_one :topic, class_name: "Forem::Topic" if defined?(Forem) && defined?(Forem::Topic)

  has_many :place_albums, dependent: :destroy
  has_many :places, through: :place_albums
  has_many :title_place_albums, -> { where(in_title: true) }, class_name: "PlaceAlbum"
  has_many :title_places, through: :title_place_albums, source: :place
  has_many :place_mentioned_albums, -> { where(in_title: false) }, class_name: "PlaceAlbum"
  has_many :places_mentioned, through: :place_mentioned_albums, source: :place

  has_many :place_albums_in_areas, dependent: :destroy, class_name: "PlaceAlbumInArea"
  has_many :areas, -> { order "area" }, through: :place_albums_in_areas, source: :place

  has_many :photos, -> { order :time }
  has_many :comments, through: :topic, source: :posts, class_name: "Forem::Post" if defined?(Forem) && defined?(Forem::Post)

  has_many :route_albums, dependent: :destroy
  has_many :routes_mentioned, through: :route_albums, source: :route

  validates :user_id, presence: true
  validates_length_of :title, maximum: 128
  validates_length_of :description, maximum: 30720

  SORT_OPTIONS = {
    "title" => "title",
    "date_created" => "created_at DESC",
    "last_liked" => "last_liked_at DESC NULLS LAST",
    "last_commented" => "last_comment_at DESC NULLS LAST",
    "total_likes" => "total_likes DESC NULLS LAST",
    "total_comments" => "total_comments DESC NULLS LAST"
  }
  DEFAULT_SORT = "date_created"

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
    "Album: #{title}"
  end

  def latitude
    ref_latitude
  end

  def longitude
    ref_longitude
  end

  # Called when a recommendation is added to the album.
  def recommendationAdded
  end

  # My list function for model index pages.
  # Lists all models with title >= lower and <= upper
  def self.list(sort = DEFAULT_SORT, lower = nil, upper = nil)
    if !lower.nil? && !upper.nil? && sort == "Title"
      where("LEFT(title,:length) >= :lower AND LEFT(title,:length) <= :upper", { lower: lower, upper: upper, length: lower.length }).order(SORT_OPTIONS[sort])
    else
      where("deleted IS NULL OR NOT deleted").order(SORT_OPTIONS[sort])
    end
  end

  # Returns which forum to use for a topic about this album.
  def forum
    area = areas.where("forum_id IS NOT NULL").order(:area).first
    area.nil? ? (defined?(Forem::Forum) ? Forem::Forum.find_by_name("Other Regions") : nil) : area.forum
  end

  def set_links
    place_albums.delete_all
    route_albums.delete_all
    self.place_id = nil
    return if deleted
    set_places title, description
  end

  private

  # Insert this album into existing areas it is located in to avoid having to refresh the area page.
  def addToAreas
    place_albums_in_areas.delete_all
    Place.areas.each do |area|
      if area.inArea(self.ref_latitude, self.ref_longitude) && PlaceAlbumInArea.where(place_id: area.id, album_id: self.id).empty?
        PlaceAlbumInArea.create(place_id: area.id, album_id: self.id)
      end
    end
  end
end
