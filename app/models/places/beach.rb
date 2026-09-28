class Beach < Place
  MARKER_ICON = 'hotsprings.png'
  MARKER_SHADOW = 'hotsprings.shadow.png'

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.article_trim_strings += %w(beach)
end
