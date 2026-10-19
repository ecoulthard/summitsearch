class LegacyForumModeratorGroup < ApplicationRecord
  self.table_name = "forem_moderator_groups"

  def readonly?
    true
  end
end
