module ForumPostContent
  def filtered_content(view_context, users_provider: Thredded::UsersProvider, **options)
    if source != "forem"
      return super unless content.to_s.match?(/\[\[photo=\d+\]\]/)

      parts = content.to_s.split(/(\[\[photo=\d+\]\])/).map do |part|
        if part.match?(/\A\[\[photo=\d+\]\]\z/)
          view_context.render(partial: "articles/legacy_forum_content", locals: { content: part })
        else
          Thredded::ContentFormatter.new(view_context, users_provider: users_provider,
            users_provider_scope: readers, **options).format_content(part)
        end
      end
      return view_context.safe_join(parts)
    end

    view_context.render(partial: "articles/legacy_forum_content", locals: { content: content })
  end
end
