module ForumNavigationHelper
  def forum_navigation_groups
    viewer = current_user || Thredded::NullUser.new
    boards = Thredded::MessageboardPolicy::Scope.new(viewer, Thredded::Messageboard.all).resolve
      .includes(:group).order(:position, :id)
    boards.group_by(&:group)
  end

  def forum_suggestions_path
    viewer = current_user || Thredded::NullUser.new
    boards = Thredded::MessageboardPolicy::Scope.new(viewer, Thredded::Messageboard.all).resolve
    board = boards.find_by(forem_slug: "suggestions") || boards.find_by(forem_forum_id: 21)
    board ? thredded.messageboard_topics_path(board) : thredded.root_path
  end
end
