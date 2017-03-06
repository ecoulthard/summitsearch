ThinkingSphinx::Index.define :album, :with => :active_record do
  # fields
  indexes title, :sortable => true
  indexes description

  # attributes
  has importance, deleted
end
