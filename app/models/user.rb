class User < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  cattr_reader :per_page
  @@per_page = 100
  scope :recent_first, -> { where('confirmed_at IS NOT NULL').order('created_at DESC') }
  has_many :places
  has_many :photos
  has_many :photos_by_time, -> { order 'time DESC NULLS LAST, created_at DESC' }, :class_name => 'Photo'
  has_many :recently_submitted_photos, -> { order 'created_at DESC' }, :class_name => 'Photo'
  has_many :updated_photos, -> { order 'updated_at DESC' }, :class_name => 'Photo'

  def popular_photos
    photos.joins(:visits => :ip_address).where("ip_addresses.user_id IS NULL OR ip_addresses.user_id <> photos.user_id").group("photos.id").order("count(visits.id) + 3*COALESCE(photos.total_likes,0) DESC NULLS LAST")
  end
  
  has_many :trip_reports, -> { order 'start_time DESC NULLS LAST, created_at DESC' }
  def trip_reports_by_year
    trip_reports.includes(:route).group_by{|t| t.start_time.nil? ? 'Unknown Year' : t.start_time.year}
  end
  def trip_reports_by_sub_region
     trip_reports.includes(:route).includes(route: :sub_region).group_by {|t| t.route.sub_region }
  end

  has_many :albums, -> { order 'time DESC NULLS LAST, created_at DESC' }
  has_many :routes

  #Add a trip list for each user for each route subclass
  #Also add a grouping for each subregion
  Route.subclasses.each do |subclass|
    body = proc { trip_reports.joins(:route).where("routes.type='#{subclass.to_s}'") }
    class_eval { define_method(subclass.to_s.tableize,&body) }
    body = proc {
      trip_reports.joins(:route).where("routes.type='#{subclass.to_s}'").group_by {|t|
        t.route.sub_region
      }
    }
    class_eval { define_method("#{subclass.to_s.tableize}_by_sub_region",&body) }
  end
  def other_trips
    trip_reports.joins(:route).where("routes.type='Route'")
  end

  has_many :user_photos
  has_many :photo_views, :through => :user_photos, :source => :photo
  has_many :ip_addresses, -> { order 'last_visit_at DESC NULLS LAST' }
  has_many :album_visits, -> { order 'updated_at DESC' }, :through => :ip_addresses
  has_many :albums_visited, :through => :album_visits, :source => :album
  has_many :place_visits, -> { order 'updated_at DESC' }, :through => :ip_addresses
  has_many :places_visited, :through => :place_visits, :source => :place
  has_many :photo_visits, -> { order 'updated_at DESC' }, :through => :ip_addresses
  has_many :photos_visited, :through => :photo_visits, :source => :photo
  has_many :route_visits, -> { order 'updated_at DESC' }, :through => :ip_addresses
  has_many :routes_visited, :through => :route_visits, :source => :route
  has_many :trip_report_visits, -> { order 'updated_at DESC' }, :through => :ip_addresses
  has_many :trip_reports_visited, :through => :trip_report_visits, :source => :trip_report
  has_many :topics, :class_name => "Forem::Topic"
  has_many :posts, :class_name => "Forem::Post"
  has_many :forem_views, :class_name => "Forem::View"

  has_attached_file :photo, :styles => { :medium => "600x600>", :thumb => "150x150>" }, :url => "/system/users/:attachment/:id/:style/:basename.:extension",  
  :path => ":rails_root/public/system/users/:attachment/:id/:style/:basename.:extension"

  SORT_OPTIONS = {'name' => "IFNULL(NULLIF(username,''), realname)", 'date_created' => 'created_at DESC'}
  DEFAULT_SORT = 'date_created'

  after_destroy :ensure_an_admin_remains
  before_create :set_contributor_until

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  #def user_params
  #  params.require(:person).permit(:email, :password, :password_confirmation, :id, :username, :realname, :country, :province, :city, :description, :home_page, :photo, :photo_caption, :signature, :last_photo_uploaded_at)
  #end

  ROLES = %w(Admin Editor Author)
  validates_inclusion_of :role_index, :in => 0..ROLES.length-1

  validates_attachment_size :photo, :less_than => 5.megabytes, :if => :has_photo?
  validates_attachment_content_type :photo, :content_type => ['image/jpeg', 'image/png'], :if => :has_photo?
  validates_uniqueness_of :username, :allow_nil => true
  validates :realname, :presence => true

  extend FriendlyId
  friendly_id :slug_field, use: [:slugged, :history, :finders]

  def slug_field
    return nil if display_name.nil?
    display_name.downcase.gsub " ", "-"
  end

  #Anyone can read the forums
  def can_read_forem_forums?
    true
  end

  #Anyone can read the forums
  def can_read_forem_forum? forum
    true
  end

  #Anyone can read the forums
  def can_read_forem_category? category
    true
  end

  #Anyone can create a topic
  def can_create_forem_topics? forum
    true
  end

  #Anyone can reply to a topic
  def can_reply_to_forem_topic? topic
    true
  end

  #Anyone can read the forums
  def can_read_forem_topic? topic
    true
  end

  def can_edit_forem_posts? forum
    true
  end

  def to_s
    display_name
  end

=begin
  searchable do
    text :display_name#, :boost => 20
    text :description
    text :photo_caption
    integer :importance do 1 end
  end
=end

  #Search friendly parameters
#  def to_param
#    "#{id}-#{display_name.parameterize}"
#  end

   # A summary string to use for autocomplete
  def autocomplete_summary
    summary = "Member: #{display_name}"
  end

  #My list function for model index pages.
  #Lists all models with title >= lower and <= upper
  def self.list sort=DEFAULT_SORT, lower=nil, upper=nil
    if !lower.nil? && !upper.nil? #Grab alphabetical interval of albums
      where("confirmed_at IS NOT NULL && ((LEFT(username,:length) >= :lower AND LEFT(username,:length) <= :upper) OR ((username IS NULL OR username = '') AND LEFT(realname,:length) >= :lower AND LEFT(realname,:length) <= :upper))", {:lower => lower, :upper => upper, :length => lower.length }).order(SORT_OPTIONS[sort])
    else
      where('confirmed_at IS NOT NULL').order(SORT_OPTIONS[sort])
    end
  end

  def ensure_an_admin_remains
    if User.where("role_index = ?", User::ROLES.index("Admin")).count.zero?
      raise "Can't delete last admin"
    end
  end

  def display_name
    self.username.blank? ? self.realname : self.username
  end

  #For first year everyone gets free access until October
  def set_contributor_until
    self.contributer_until = "Oct 1 2011"
    self.content_contributer_until = "Oct 1 2011"
  end

  def role
  	User::ROLES[self.role_index]
  end

  #Define role identification and search functions
  ROLES.each_with_index do |role, index|
    define_method("is_#{role.downcase}?") { self.role_index <= index } unless method_defined? "is_#{role.downcase}?"
  end

  def self.find_admins
    where("role_index <= :index",  {:index => ROLES.index("Admin")})
  end

  #Start section about contributions
  NEW_FEATURE_CONTRIBUTION_AMOUNT = 3.days
  NEW_AREA_CONTRIBUTION_AMOUNT = 4.weeks
  NEW_BULLETIN_CONTRIBUTION_AMOUNT = 1.day
  NEW_ROUTE_CONTRIBUTION_AMOUNT = 1.week
  NEW_TRIP_CONTRIBUTION_AMOUNT = 1.week
  NEW_TRIP_2ND_CONTRIBUTION_CUTOFF = 2 #Recommendations 
  NEW_TRIP_2ND_CONTRIBUTION_AMOUNT = 1.week 
  NEW_TRIP_3RD_CONTRIBUTION_CUTOFF = 6 #Recommendations 
  NEW_TRIP_3RD_CONTRIBUTION_AMOUNT = 1.week 
  NEW_PHOTO_CONTRIBUTION_AMOUNT = 3.days  
  NEW_PHOTO_2ND_CONTRIBUTION_CUTOFF = 2 #Recommendations 
  NEW_PHOTO_2ND_CONTRIBUTION_AMOUNT = 3.days 
  NEW_PHOTO_3RD_CONTRIBUTION_CUTOFF = 6 #Recommendations 
  NEW_PHOTO_3RD_CONTRIBUTION_AMOUNT = 3.days
  MAX_ACCESS_TIME = 3.years #No time can be added after this amount has been reached.

  #Add time to current_content_contribution_time or now if less than now
  #If sum time is greater than 3 years truncate it to be 3 years
#  def add_content_contribution_time time_amount
#    if current_content_contributer?
#      #truncate time if more than max amount
#      if self.content_contributer_until + time_amount > MAX_ACCESS_TIME.from_now 
#        time_amount = MAX_ACCESS_TIME.from_now - self.content_contributer_until
#      end
#      self.content_contributer_until += time_amount
#    else
#      self.content_contributer_until = Time.now + time_amount
#    end
#    add_contribution_time time_amount
#    save
#  end

  def add_paid_contribution_time time_amount
    if current_paid_contributer?
      self.paid_contributer_until += time_amount
    else
      self.paid_contributer_until = Time.now + time_amount
    end
    add_contribution_time time_amount
    save
  end

  #Add paid or unpaid contribution time
  def add_contribution_time time_amount
    if current_contributer?
      self.contributer_until += time_amount
    else
      self.contributer_until = Time.now + time_amount
    end
  end

#  def current_content_contributer?
#    return !(self.content_contributer_until.blank?) && self.content_contributer_until >= Time.now 
#  end
  
  def current_paid_contributer?
    return !(self.paid_contributer_until.blank?) && self.paid_contributer_until >= Time.now
  end

  #content + paid
  def current_contributer?
    return !(self.contributer_until.blank?) && self.contributer_until >= Time.now 
  end

  def has_photo?
    return !self.photo_file_name.blank?
  end

  def has_caption?
    return !self.photo_caption.blank?
  end  
end
