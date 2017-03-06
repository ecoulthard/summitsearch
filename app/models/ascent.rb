class Ascent < ActiveRecord::Base
  include Concerns::Viewable
  include Concerns::Visitable
  versioned
  belongs_to :mountain, :foreign_key => :place_id
  belongs_to :route
  has_many :ascent_people, :dependent => :destroy
  has_many :people, :through => :ascent_people

  accepts_nested_attributes_for :ascent_people, :allow_destroy => true, :reject_if => lambda { |a| a[:person_id].blank? }, :limit => 2000

  validates :place_id, :year, :presence => true

  #We use select instead of where so we can eager load people and do one query instead of 2*(n+1)
  def participants
    people.select{|person| !person.guide }
  end

  #We use select instead of where so we can eager load people and do one query instead of 2*(n+1)
  def guides
    people.select{|person| person.guide }
  end
end
