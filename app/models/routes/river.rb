class River < Route

  before_save :set_partial_name_match # see function
  
  #Rivers dont have destination places
  SHOW_DESTINATION_PLACE = false
  #Can you link the route to articles
  PHOTO_LINKABLE = true

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(mount lake)
  self.article_trim_strings += %w(river creek)
end
