class AscentPerson < ActiveRecord::Base
  belongs_to :ascent
  belongs_to :person
  #For some reason the validation fails and prevents submission
  #validates :ascent_id, :person_id, :guide, :leader, :presence => true
  #attr_accessible :ascent_id, :guide, :leader, :person_id
end
