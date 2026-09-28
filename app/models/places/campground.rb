class Campground < Place
  MARKER_ICON = 'campground.png'
  MARKER_SHADOW = 'campground.shadow.png'

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(lake)
  self.article_trim_strings += %w(Campground)
end
