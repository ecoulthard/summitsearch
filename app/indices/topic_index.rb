ThinkingSphinx::Index.define :"forem/topic", :with => :active_record do
  # fields
  indexes subject, :sortable => true

  has last_post_at
end

=begin
  searchable do
    text(:text) { |t| t.posts.collect { |p| p.text } }
    text :subject#, :boost => 10
    string(:author) { |t| t.posts.by_created_at.first.user.display_name }
    integer(:forum_id)
    string(:subject) { |t| t.help.strip_tags(t.subject) }
    time(:last_post_at) { |t| t.last_post_at }
    integer(:num_replies) { |t| t.posts.count }
    integer(:num_views) { |t| t.views_count }
  end
=end

