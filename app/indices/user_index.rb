ThinkingSphinx::Index.define :user, :with => :active_record do
  # fields
  indexes username, :sortable => true
  indexes photo_caption
  indexes description

  # attributes
  #has importance
end
