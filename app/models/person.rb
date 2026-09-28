require 'find'

#This class is for important present or historic people who likely don't have a user account.
class Person < ApplicationRecord
  include Viewable
  include Visitable

  cattr_reader :per_page
  @@per_page = 100
  default_scope { order(:name) }
  belongs_to :user, foreign_key: "insert_id", optional: true
  belongs_to :updater, foreign_key: "update_id", class_name: "User", optional: true
  has_many :ascent_people
  has_many :ascents, -> { order :ascent_index }, through: :ascent_people
  has_many :mountains, through: :ascents, source: :place
  has_many :namings, class_name: "Name"
  has_many :placenames, class_name: "Person"

  has_one_attached :photo do |attachable|
    attachable.variant :medium, resize_to_limit: [600, 600]
    attachable.variant :thumb, resize_to_limit: [150, 150]
  end

  SORT_OPTIONS = {'name' => "name", 'date_created' => 'created_at DESC'}
  DEFAULT_SORT = 'name'
  
  before_validation :sync_attachment_attributes
  validate :validate_photo_attachment, :if => :has_photo?
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

  def validate_photo_attachment
    return unless photo.attached? && photo.blob.present?

    if photo.blob.byte_size > 5.megabytes
      errors.add(:photo, "must be less than 5MB")
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
    self.photo_updated_at = Time.current if respond_to?(:photo_updated_at=)
  end

  def has_photo?
    photo.attached? || !self.photo_file_name.blank?
  end

  def has_caption?
    return !self.photo_caption.blank?
  end

end
