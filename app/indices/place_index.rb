ThinkingSphinx::Index.define :place, with: :active_record do
  # fields
  indexes name, sortable: true
  indexes alternate_names
  indexes match_names
  indexes description

  # attributes
  has importance, area
end
