class IpAddress < ActiveRecord::Base
  belongs_to :user
  has_many :visits, :dependent => :destroy
  has_many :album_visits, -> { where("visitable_type = 'Album'") }, :class_name => "Visit"
  has_many :albums, :through => :album_visits, :source => :album
  has_many :place_visits, -> { where("visitable_type = 'Place'") }, :class_name => "Visit"
  has_many :places, :through => :place_visits, :source => :place
  has_many :photo_visits, -> { where("visitable_type = 'Photo'") }, :class_name => "Visit"
  has_many :photos, :through => :photo_visits, :source => :photo
  has_many :route_visits, -> { where("visitable_type = 'Route'") }, :class_name => "Visit"
  has_many :routes, :through => :route_visits, :source => :route
  has_many :trip_report_visits, -> { where("visitable_type = 'TripReport'") }, :class_name => "Visit"
  has_many :trip_reports, :through => :trip_report_visits, :source => :trip_report
  validates :address, :visit_count, :first_visit_at, :last_visit_at, :last_http_user_agent, :presence => true

  SORT_OPTIONS = {'last_visit_at' => "last_visit_at DESC NULLS LAST", 'first_visit_at' => 'first_visit_at DESC NULLS LAST', 'visit_count' => 'visit_count DESC NULLS LAST'}
  DEFAULT_SORT = 'last_visit_at'

  def display_name
    user.nil? ? address : "#{user.display_name} at #{address}"
  end

  #My list function for model index pages.
  #Lists all models
  def self.list sort=DEFAULT_SORT
    order(SORT_OPTIONS[sort])
  end

end
