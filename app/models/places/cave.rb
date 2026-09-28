class Cave < Place
  
  MARKER_ICON = 'cave.png'
  MARKER_SHADOW = 'cave.shadow.png'

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(the lake)
  self.article_trim_strings += %w(cave)
end
