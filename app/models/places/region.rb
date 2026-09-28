class Region < Place
  #Highest level of area on the site
  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.article_trim_strings += %w()
end
