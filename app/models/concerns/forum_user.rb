module ForumUser
  extend ActiveSupport::Concern

  def thredded_admin?
    forem_admin?
  end

  def thredded_can_moderate_messageboards
    boards = Thredded::Messageboard
    return boards.all if thredded_admin?
    return boards.none unless persisted?

    # Step 3 will add and populate this explicit mapping. Never infer grants
    # from matching primary keys or names on independently created boards.
    return boards.none unless boards.table_exists? && boards.column_names.include?("forem_forum_id")

    groups = LegacyForumMembership.where(member_id: id).select(:group_id)
    forums = LegacyForumModeratorGroup.where(group_id: groups).select(:forum_id)
    boards.where(forem_forum_id: forums)
  end

  def thredded_can_moderate_messageboard?(messageboard)
    thredded_admin? || (messageboard.persisted? && thredded_can_moderate_messageboards.exists?(messageboard.id))
  end
end
