ThinkingSphinx::Index.define :trip_report, with: :active_record do
  # fields
  indexes title, sortable: true
  indexes abstract
  indexes participants
  indexes description

  # attributes
  has importance
end
