ThinkingSphinx::Index.define :person, :with => :active_record do
  # fields
  indexes name, :sortable => true
  indexes photo_caption
  indexes description

  # attributes
  has importance
end


