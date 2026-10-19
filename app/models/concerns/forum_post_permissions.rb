module ForumPostPermissions
  def create?
    !@user.thredded_anonymous? && !@post.postable.locked? && !@post.postable.blocked? &&
      Thredded::TopicPolicy.new(@user, @post.postable).read? && super
  end
end
