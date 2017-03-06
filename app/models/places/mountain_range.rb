class MountainRange < Place 
  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.article_trim_strings += %w(range)
end
