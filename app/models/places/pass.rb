class Pass < Place
  
  MARKER_ICON = 'pass.png'
  MARKER_SHADOW = 'pass.shadow.png'
  
  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(the lake)
  self.article_trim_strings += %w(pass col)
end
