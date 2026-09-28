class AscentPerson < ApplicationRecord
  belongs_to :ascent, optional: true
  belongs_to :person, optional: true
  #For some reason the validation fails and prevents submission
  #validates :ascent_id, :person_id, :guide, :leader, :presence => true
  #attr_accessible :ascent_id, :guide, :leader, :person_id
end
