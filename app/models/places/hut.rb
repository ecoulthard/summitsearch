class Hut < Place
  MARKER_ICON = 'hut.png'
  MARKER_SHADOW = 'hut.shadow.png'

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(lake)
  self.article_trim_strings += %w(Hut Lodge Cabin Hostel)
end
