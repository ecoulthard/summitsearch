module ArticleMatchHelper
#This module contains functions for places to help them be linked to articles and albums

  #Defaults to be used for inheritable arrays in each class this is included by.
  DEFAULT_BEFORE_NAME_ARTICLE_ACCEPT_STRINGS = []
  DEFAULT_BEFORE_NAME_ARTICLE_REJECT_STRINGS = ["from", "west of", "north of", "east of", "south of", "from the summit of", "below", "above", "camp on"]
  #Each subclass will remove the apropriate items from this list so that they match
  DEFAULT_AFTER_NAME_ARTICLE_REJECT_STRINGS = ["peak", "mountain", "glacier", "lake", "hut", "lodge", "falls", "pass", "col", "camp", "cabin", "cave", "spring", "meadow", "canyon", "river", "creek", "col", "ne\\d", "nw\\d", "se\\d", "sw\\d", "n\\d", "e\\d", "s\\d", "w\\d", "range", "island", "icefield", "highway", "road", "trail", "park", "summit view", "is occluded"]
  DEFAULT_ARTICLE_TRIM_STRINGS = %w(the)


  def trim_content
    self.name.strip! unless self.name.nil?
    self.alternate_names.strip! unless self.alternate_names.nil?
    self.match_names.strip! unless self.match_names.nil?
    self.reject_names.strip! unless self.reject_names.nil?
  end

  #Should return one of the title photos. Should select based on quality. No panoramas.
  def title_photo
    return title_photos.where("photo_width / photo_height < 3").first
  end

  #Should return one of the title photos for a thumbnail. Should select based on quality.
  def thumb_title_photo
    title_photo
  end

  #Raw names = Name + Aliases + Alternate Names, downcased
  def raw_names
    raw_names = [name.downcase] + aliases.downcase.split(%r{,\s*})
    raw_names += alternate_names.downcase.split(%r{,\s*}) if !alternate_names.nil?
    raw_names
  end

  #Returns all names of place with generic words removed such as 'Mountain' 
  def trimmed_names 
    trimmed_names = []
    raw_names.each do |name|
      article_trim_strings.each do |trim| #Remove all trim words from name
        name = !name.index(trim).nil? ? name.sub(trim, "") : name
      end
      name = name.strip
      if(name.length > 5)
	trimmed_names << name #Add trimmed name to the list
      end
    end
    trimmed_names
  end

  #All the non trimmed names that can match.
  #These are not necessarily fully qualified.
  #So they should not be used for linking.
  def full_names
    names = raw_names
    if match_names
      names += match_names.downcase.split(%r{,\s*})
    end
    names
  end

  #Returns all non trimmed names that if present in a articles caption or title may indicate the presence
  #of this place in the article
  def articleFullyQualifiedMatchNames
    #Add raw_names and article_match strings first
    names = []
    #Add any words required for a match before each name
    if before_name_article_accept_strings.length != 0
      raw_names.each do |name|
	before_name_article_accept_strings.each do |string|
	  names << string + " " + name
	end
      end
    else
      names = raw_names
    end

    #Add additional article matches to the list
    if(!match_names.nil?)
      names += match_names.downcase.split(%r{,\s*})
    end
    names
  end

  #Returns all partial names that if present in a articles caption or title
  #might indicate the presence of this place in the article
  def articlePartialMatchNames
    names = []
    if partial_name_match #If partial name matches are allowed for this place
      #Add any words required for a match before each trimmed name
      if before_name_article_accept_strings.length != 0
	trimmed_names.uniq.each do |name|
	  before_name_article_accept_strings.each do |string|
	    names << string + " " + name
	  end
	end
      else
	names += trimmed_names
      end
    end
    names
  end

end
