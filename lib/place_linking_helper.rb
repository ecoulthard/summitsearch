module PlaceLinkingHelper

  LARGE_LINKING_RADIUS = 100 #KMs, Used for mountains and places
  LINKING_RADIUS = 60 #KMs, Used for everything else

#This module contains functions for Photos and Albums (here on refered to as articles) to link them to places based on the text in the title, caption or description.

  #Returns all the places and routes linked to this album. Used by the show method in the controller
  def places
    photo_places = title_places + places_mentioned + routes_mentioned
    photo_places = photo_places << route if route_id
    photo_places
  end


#This section is complicated so put on your thinking cap.
#
#We want to link the article to any nearby places that the author writes about in the title,
#caption or description. Sometimes the author may refer to a partial name of a place such as "Athabasca"
#instead of "Mount Athabasca". Sometimes the author may use a nickname such as "AthaB".

#If we automatically link "Mount Athabasca to an article if we see the word "Athabasca" then we would also link
#articles of the "Athabasca Glacier" to "Mount Athabasca". So there are some words that if they follow the word
#we are matching then the article doesn't match that place.

#There are also words that if they precede the word we are matching then the article or album doesn't match the
#place. Like if you see the phrase "From Mount Athabasca" then the article was taken on "Mount Athabasca" but
#is not of "Mount Athabasca"

#Some partial names conflict with commonly used english words or with other nearby mountains. "Mount Low"
#conflicts with the words "low" and "below". So we cannot look for the shortened version of this name in a
#sentence without making many incorrect links. "Edward Peak" has the partial name "Edward" which also exists
#in "Mount King Edward". So we cannot look for the partial name for "Edward Peak" in all nearby articles without
#linking articles of "Mount King Edward" to "Edward Peak".

#We also want to check longer place names first for exact matches. Like "Tonquin Valley Backcountry Lodge"
#needs to match the place called "Tonquin Valley Backcountry Lodge" and not "Tonquin Valley".

#In addition to these concerns there might be other things that come up that cause us to mislink articles
#In order to fix these unforseen cases we also have 2 fields for specifying phrases that definitely
#match the place or definitely do not match the place. We could for instance put "AthaB" in the definite
#match list for "Mount Athabasca" and then this nickname would match a article to "Mount Athabasca".

#Having said all that, the following functions looks for all nearby places. They look for fully qualified
#names for all nearby places first before they look for partial matches. If they find a match they then look
#for words that if they come before the match disqualify the place from being a match. They then look for
#words that if they come after a match disqualify the place. If the place is disqualified from a match they
#don't try and match the place using any of its other names, they immediately move to the next place. If the
#match passes the tests they make a link. If the match is in the title of the article then that means the place
#is more important in the article than places only mentioned in the caption. So this link will appear in the "Title Photos"
#of that place instead of the "Mentioned In".

  def set_places title="", description=""
    return if title.blank? && description.blank? #return if there is no text to match.
    lat = (defined?(self.latitude) && self.latitude.nil?) ? ref_latitude : latitude
    lon = (defined?(self.longitude) && self.longitude.nil?) ? ref_longitude : longitude

    return if lat.nil? || lon.nil?

    #We need a separator between description and title to prevent description being mistaken for context
    #in the title. Eg "North Face of Athab" "Mountains to the South with AthaB featured prominently"
    #would have "Athab" rejected without a separator because "Mountains" occurs immediatly after it.
    text = (title.nil? ? "" : title)+ "::" + (description.nil? ? "" : description)
    title_text = (title.nil? ? '' : title.downcase)
    numPlacesInTitle = 0
    text = text.downcase
    places = []
#puts River.find_by_radius(lat,lon,100).to_yaml
    [Place, River, Road].each_with_index do |place_class, index|
      places += place_class.find_by_radius(lat, lon, LINKING_RADIUS).order('length(name) DESC')
    end
    places += Mountain.find_by_radius(lat, lon, LARGE_LINKING_RADIUS).order('length(name) DESC')
    places = places.sort {|a,b| a.name.length <=> b.name.length}
    places = places.reverse
    numPlacesInTitle = findMatches(text, title_text, places, "articleFullyQualifiedMatchNames", numPlacesInTitle, lat, lon)
    numPlacesInTitle = findMatches(text, title_text, places, "articlePartialMatchNames", numPlacesInTitle, lat, lon)
    #Remove extra "also appearing in" links if article is a title article
    self.send("route_#{self.class.to_s.downcase}s").find_by_route_id(self.route_id).delete unless self.route_id.nil?
  end #def

  #Finds matches to the given text with the given places using the given method to retrieve
  #match names from each place. Returns the updated numPlacesInTitle
  def findMatches text, title_text, places, method, numPlacesInTitle, lat, lon
    #Look for name matches for each nearby place
#puts "text:     #{text}"
    places.each do |place|
      place_class = place.class.superclass
      place_article_class = (place_class.to_s + self.class.to_s).constantize
      place_articles = place.send(place_class.to_s.downcase + "_" + self.class.to_s.downcase.pluralize)
      place_id_tag = place_class.to_s.downcase + "_id"
      #No matching large areas
      next if place_class == Place && place.area.present? && place.area > Place::MAX_AREA_FOR_TITLE_ARTICLES
#puts "Checking Place: (#{place.name})\n"
      place.send(method).each do |name|  #Look for all name matches in the text
        matchIndex = (text =~ /^(.*\W)?#{name}(\W.*)?$/) #index of a match if one exists
        if !matchIndex.nil? # Got a potential match
	  matchIndex = (text =~ /#{name}/)
          match = true
#puts "Potential Match: #{name}\n"
          before_text = text[0..matchIndex-1]
          after_text = text[matchIndex+name.length..text.length-1]
          #Look for reject words after the name. If we find one then the place is not in the article
          place.after_name_article_reject_strings.each do |reject|
	    #Found a reject name in the text. Place is not in the article
	    if after_text.match("^\s+" + reject)
       	      match = false
#puts "After Rejected by (#{reject})"
              break
            end
          end #end after reject names

          #Look for reject words before the name. If we find one then the place is not in the article
	  if(matchIndex > 0)
            place.before_name_article_reject_strings.each do |reject|
              #Found a reject name in the text. Place is not in the article
	      if before_text.match(reject + "\s+$")
	        match = false
#puts "Before Rejected by (#{reject})"
                break
              end
            end #end before reject names
	  end

	  #Look for place specific reject names in the text. If one is found then the place is not in the article
	  if(!place.reject_names.nil?)
	    place.reject_names.downcase.split(%r{,\s*}).each do |reject|
	      rejectMatchIndex = (text =~ /^(.*\W)?#{reject}(\W.*)?$/) #index of a reject if one exists
              #Found a reject name in the text. Place is not in the article
	      if !rejectMatchIndex.nil? # Got a reject match
	        match = false
#puts "Place Rejected by (#{reject})"
                break
              end
	    end
	  end

          #Check for rare situation where 2 nearby places exist with the same name.
          #If this match is on the name then only match the closest of the 2 places.
          #We use next to keep the name in the text for when the closest place comes up.
	  if match && defined?(place.nearby_namesake_id) && !(place.nearby_namesake_id.nil?)
            next if place.dist(lat,lon) >= place.nearby_namesake.dist(lat,lon)
          end

          if match #Create a link
#puts "Name Accepted: #{name}\n"
	    in_title = false
	    #The place is in the title if we can find an alias
	    place.send(method).each do |name|
	      in_title |= title_text.include? name
	    end
           
	    #If a previous link exists from previous passes then only keep one with preferrence for in_title=true 
	    #previous_links = place_article_class.where("#{place_id_tag}=:place_id AND #{self.class.to_s.downcase}_id=:article_id", :place_id => place.id, :article_id => id)
	    #previous_links = place_article_class.where(":place_id_tag=:place_id AND :id_field=:article_id", :place_id_tag => place_id_tag, :place_id => place.id, :id_field => self.class.to_s.downcase + "_id", :article_id => id)
	    previous_links = place_article_class.where(place_id_tag.to_sym => place.id, (self.class.to_s.downcase + "_id").to_sym => id)

            #If in title then delete any previous links
	    previous_links.delete_all if in_title
            #Don't add link if another link exists that may be more important than this one
	    break if previous_links.exists?

            place_article_class.create(place_id_tag => place.id,"#{self.class.to_s.downcase}_id" => id, :in_title => in_title)
	    #If route match is in the title set title route
            self.route_id = in_title ? place.id : route_id if place_class == Route 
	    #If match is in the title increment the title match count
	    numPlacesInTitle += in_title ? 1 : 0
	    

	  else
#puts "Name Rejected: #{name}\n"
          end #if match
	  #Remove names from text whether or not it matched to prevent conflicts with other placenames
	  #EG: "From East Stutfield Peak" should not match Stutfield Peak
	  place.send(method).each do |name|
	    text.gsub!(name, "")#Remove name from text to avoid matches with places with subnames
	    title_text.gsub!(name, "")#Remove name from title_text to avoid matches with places with subnames
	  end
          break#Out of names loop and start checking next place
        end #if potential match
      end #names
    end #places
    numPlacesInTitle
  end

end
