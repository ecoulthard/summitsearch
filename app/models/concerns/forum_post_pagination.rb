module ForumPostPagination
  def calculate_page(posts, per_page)
    table = posts.arel_table
    before = table[:created_at].lt(created_at).or(
      table[:created_at].eq(created_at).and(table[:id].lt(id))
    )
    1 + posts.where(before).count / per_page
  end
end
