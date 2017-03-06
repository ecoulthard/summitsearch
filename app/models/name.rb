class Name < ActiveRecord::Base
  belongs_to :place
  belongs_to :route
  belongs_to :person
  belongs_to :named_after_person, :class_name => "Person"

  validates :name, :presence => true
end
