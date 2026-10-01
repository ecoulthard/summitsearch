if defined?(Forem) && defined?(Forem::Topic)
  ThinkingSphinx::Index.define :"forem/topic", with: :active_record do
    # fields
    indexes subject, sortable: true

    has last_post_at
  end
end

