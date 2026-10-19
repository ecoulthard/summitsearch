# Historical visits are retained without loading retired polymorphic classes.
class LegacyForumView < ApplicationRecord
  self.table_name = "forem_views"

  def readonly?
    true
  end
end
