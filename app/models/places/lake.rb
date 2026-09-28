class Lake < Place

  MARKER_ICON = 'water.png'
  MARKER_SHADOW = 'water.shadow.png'
  MARKER_ICON_GOV_GOOGLE = 'water_gov_google.png'

  #Words that almost for sure mean they are searching for a mountain. Spaces are important.
  SEARCH_KEY_WORDS = [" lake", "lake ", "lk. ", "lk ", " lk.", " lk"]

  self.before_name_article_accept_strings.clear
  self.before_name_article_accept_strings = %w()
  self.before_name_article_reject_strings += %w(the)
  self.article_trim_strings = %w(lake)

  def shortname
    self.name.gsub(' Lake', '').gsub('Lake ', '')
  end

  #When people refer to a lake they can use Lake Name, Name Lake, Lk. Name ...etc
  def aliases
    myAliases = ""
    if self.name.include?('Lake')
      short = shortname
      myAliases = "#{short} Lake, Lake #{short}, Lk. #{short}, Lk #{short}" 
    end
    myAliases
  end

end
