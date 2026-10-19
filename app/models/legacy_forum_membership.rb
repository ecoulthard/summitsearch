class LegacyForumMembership < ApplicationRecord
  self.table_name = "forem_memberships"

  def readonly?
    true
  end
end
