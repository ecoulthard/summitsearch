class TripReport < ActiveRecord::Base
  include Concerns::Viewable
  include Concerns::Visitable
  versioned
  cattr_reader :per_page
  @@per_page = 100
  belongs_to :user
  belongs_to :updater, :foreign_key => "update_id", :class_name => "User"
  belongs_to :route
  has_one :topic, :class_name => "Forem::Topic"

  has_many :photos, -> { order :time }
  has_many :comments, :through => :topic, :source => :posts, :class_name => "Forem::Post"

  validates :user_id, :title, :description, :presence => true
  validates_length_of :title, maximum: 128
  validates_length_of :abstract, maximum: 30720
  validates_length_of :participants, maximum: 30720
  validates_length_of :description, maximum: 61440
  validate :start_time_less_than_end_time
  
  SORT_OPTIONS = {'title' => 'title', 'date_created' => 'created_at DESC', 'last_liked' => 'last_liked_at DESC NULLS LAST', 'last_commented' => 'last_comment_at DESC NULLS LAST', 'total_likes' => 'total_likes DESC NULLS LAST', 'total_comments' => 'total_comments DESC NULLS LAST'}
  DEFAULT_SORT = 'date_created'

  after_create :touch_place_route
  after_save :attach_photos

  #Search friendly parameters
  def to_param
    "#{id}-#{title.parameterize}"
  end

   # A summary string to use for autocomplete
  def autocomplete_summary
    summary = "Trip Report: #{title}"
  end

  #Only call after create
  def touch_place_route
    return if self.route_id.nil?
    route.save
    route.place.save unless route.place_id.nil?
  end

#  #After creating a route credit the maker with some amount of access time
#  def addCreateContributionTime
#    user.add_content_contribution_time User::NEW_TRIP_CONTRIBUTION_AMOUNT
#  end

  #Called when a recommendation is added to the trip report.
  #Used to add contribution time if the trip report was recommended enough times.
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

  #Returns which forum to use for topics about this trip report.
  def forum
    route.forum
  end

  #My list function for model index pages.
  #Lists all models with title >= lower and <= upper
  def self.list sort=DEFAULT_SORT, lower=nil, upper=nil
    if !lower.nil? && !upper.nil? && sort=="Title" #Grab alphabetical interval of trip reports
      where("LEFT(title,:length) >= :lower AND LEFT(title,:length) <= :upper", {:lower => lower, :upper => upper, :length => lower.length }).order(SORT_OPTIONS[sort])
    else
      order(SORT_OPTIONS[sort])
    end
  end

  #sqlite doesn't like hours with leading 0's. So 2010-11-15 09:00:00 will not work for sqlite.
  #Don't know about mysql
  def self.find_by_time time
    #will find a trip report that matches the time give or take an hour
    timeplusonehour = (time.to_time + 30.minutes).to_datetime
    timeminusonehour = (time.to_time - 30.minutes).to_datetime
    TripReport.where("start_time <= :timeplusonehour and end_time >= :timeminusonehour", {:timeplusonehour => timeplusonehour, :timeminusonehour => timeminusonehour})
  end

  #Finds unassigned photos to attach to the trip report. Looks for photos taken place at the same time
  #Actually it just tells the photos it identifies as belonging to this trip to update
  #The before save functions in photo.rb will attach each photo to the trip.
  def attach_photos
    return if self.start_time.nil? || self.end_time.nil?
    Photo.find_by_time(self.start_time, self.end_time).where("trip_report_id IS NULL").each do |photo|
      if photo.user == self.user#Found definite match
        photo.set_trip_report
	photo.save
#     elsif self.participants.downcase.include? photo.user.display_name.downcase
      #Potential match confirm by checking for a lat closer than 1 degree
#	self.route.waypoints.each do |waypoint|
#	  if(photo.trip_report_id.nil? && waypoint.latitude+0.5 > photo.latitude && waypoint.latitude-0.5 < photo.latitude)
#	    photo.save
#	  end
#	end
      end
    end
  end

private

  def start_time_less_than_end_time
    return if self.start_time.nil? || self.end_time.nil?
    errors.add(:start_time, "must be less than end time.") if self.start_time >= self.end_time
  end

end
