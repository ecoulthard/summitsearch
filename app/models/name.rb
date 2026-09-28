class Name < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :route, optional: true
  belongs_to :person, optional: true
  belongs_to :named_after_person, :class_name => "Person", optional: true

  validates :name, :presence => true
end
