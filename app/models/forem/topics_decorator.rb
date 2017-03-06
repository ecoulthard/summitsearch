Forem::Topic.class_eval do
  include Concerns::Visitable
  class Helper
    include Singleton
    include ActionView::Helpers::SanitizeHelper
  end
  def help
    Helper.instance
  end

  belongs_to :place
  belongs_to :album
  belongs_to :photo
  belongs_to :trip_report
  has_many :uploaded_photos, :source => :parent_topic, :class_name => "Photo", :dependent => :nullify
  has_many :recent_views, -> { where("current_viewed_at > ?", 30.minutes.ago) }, :as => :viewable, :class_name => "View"
  has_many :recent_viewers, :through => :recent_views, :source => :user

  before_create :setDefaultPlace

  def last_posts n
    Forem::Post.where(:topic_id => self.id).order("created_at DESC").limit(n).reverse
  end

  private

  # Called before the topic is created. Selects the top match of a place search as the place
  def setDefaultPlace
    area = forum.place

    search_text = Riddle::Query.escape(help.strip_links(self.subject))

    results = Place.search search_text, :field_weights => { :name => 10 }

    places = []
    results.each do |place|
      places << place if area.nil? || place.areas.include?(area)
    end
    self.place_id = places.first.id if places.count > 0
  end

end
