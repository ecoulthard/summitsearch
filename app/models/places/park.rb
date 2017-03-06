class Park < Place
  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.article_trim_strings += %w(wilderness provincial national park area)

  def shortname
    self.name.gsub(' National Park', '').gsub(' Provincial Park', '').gsub(' Wilderness Area', '')
  end
end
