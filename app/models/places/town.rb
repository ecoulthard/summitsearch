class Town < Place
  MARKER_ICON = 'town.png'
  MARKER_SHADOW = 'town.shadow.png'

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w()
  self.article_trim_strings += %w(town)
end
