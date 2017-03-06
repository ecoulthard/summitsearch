class Mine < Place

  MARKER_ICON = 'mine.png'
  MARKER_SHADOW = 'mine.shadow.png'

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(lake)
  self.article_trim_strings += %w(mine)
end
