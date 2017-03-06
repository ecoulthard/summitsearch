require 'find'

#This class is for important present or historic people who likely don't have a user account.
class Person < ActiveRecord::Base
  include Concerns::Viewable
  include Concerns::Visitable
  versioned
  cattr_reader :per_page
  @@per_page = 100
  default_scope { order(:name) }
  belongs_to :user, :foreign_key => "insert_id"
  belongs_to :updater, :foreign_key => "update_id", :class_name => "User"
  has_many :ascent_people
  has_many :ascents, -> { order :ascent_index }, :through => :ascent_people
  has_many :mountains, :through => :ascents, :source => :place
  has_many :namings, :source => :name
  has_many :placenames, :source => :named_after_person, :class_name => "Person"
  has_attached_file :photo, :styles => { :medium => "600x600>", :thumb => "150x150>" }, :url => "/system/people/:attachment/:id/:style/:basename.:extension",
  :path => ":rails_root/public/system/people/:attachment/:id/:style/:basename.:extension"

  SORT_OPTIONS = {'name' => "name", 'date_created' => 'created_at DESC'}
  DEFAULT_SORT = 'name'
  
  #attr_accessible :guide, :birthdate, :deathdate, :description, :name, :photo_caption, :photo, :references
  
  validates_attachment_size :photo, :less_than => 5.megabytes, :if => :has_photo?
  validates_attachment_content_type :photo, :content_type => ['image/jpeg','image/pjpeg', 'image/png', 'image/gif']
  validates :name, :presence => true, :uniqueness => {:scope => :birthdate}

  before_save :set_importance

=begin
  searchable do
    text :name#, :boost => 20
    text :description
    text :photo_caption
    integer :importance do 1 end
  end
=end

  #My list function for model index pages.
  #Lists all models with name >= lower and <= upper
  def self.list sort=DEFAULT_SORT, lower=nil, upper=nil
    if !lower.nil? && !upper.nil? && sort=="Name" #Grab alphabetical interval of people
      where("LEFT(name,:length) >= :lower AND LEFT(name,:length) <= :upper", {:lower => lower, :upper => upper, :length => lower.length }).order(SORT_OPTIONS[sort])
    else
      order(SORT_OPTIONS[sort])
    end
  end


  #Search friendly parameters
#  def to_param
#    "#{id}-#{display_name.parameterize}"
#  end

  # A summary string to use for autocomplete
  def autocomplete_summary
    summary = "Person: #{name}"
  end

  extend FriendlyId
  friendly_id :name, use: [:slugged, :history, :finders]

  def set_importance
    self.importance = ascents.count
  end

  def has_photo?
    return !self.photo_file_name.blank?
  end

  def has_caption?
    return !self.photo_caption.blank?
  end

end
