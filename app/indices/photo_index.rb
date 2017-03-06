ThinkingSphinx::Index.define :photo, :with => :active_record do
  # fields
  indexes title, :sortable => true
  indexes caption
  indexes description

  # attributes
  has importance
end
