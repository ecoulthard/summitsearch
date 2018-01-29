class MainController < ApplicationController
  skip_before_filter :authenticate_user!, :only => [:index,:updated,:listing,:search,:terms,:contributions,:disclaimer,]
  skip_before_filter :editor_required
  skip_before_filter :admin_required
  before_filter :browsers_only, :only => [:gmap, :expire_index, :expire_gmap]
  
  caches_action :listing, :expires_in => 1.month

  def index
    @noindex = true #Don't let search engines index this page
    #Put an ugrade notice for users using old IE browser.
    if !request.user_agent.nil? && (request.user_agent.include?("MSIE 7") || request.user_agent.include?("MSIE 8"))
      flash.now[:notice] = "" if flash.now[:notice].nil?
      flash.now[:notice] += " You are using an obsolete browser. Some of the features on this site do not work on older browsers. To upgrade to a newer browser follow one of these links: <a href=\"http://www.mozilla.com/en-US/firefox/new/\">Firefox</a>, <a href=\"http://www.google.com/chrome/\">Google Chrome</a>, <a href=\"http://www.beautyoftheweb.com/\">Internet Explorer 9</a><br>"
    end

    getNewTripsAndAlbums
    getNewPhotos

    unless read_fragment(:part => 'places') 
      @places = Place.order("created_at DESC").includes(:areas).limit(12)
      @mountains = @places.where("type='Mountain'").joins(:detail)
      @place_groups = @places.in_groups_of(4)
    end
    @route_groups = Route.order("created_at DESC").includes(:user).limit(9).in_groups_of(3) unless read_fragment(:part => 'routes')
    @user_groups = User.where("confirmed_at IS NOT NULL").order("created_at DESC").limit(10).in_groups_of(5) unless read_fragment(:part => 'users')

    unless read_fragment(:part => 'liked')
      liked_trips = TripReport.where("last_liked_at IS NOT NULL AND created_at < ?", 1.week.ago).order("last_liked_at DESC").includes(:user).includes(:route).limit(9)
      liked_albums = Album.where("last_liked_at IS NOT NULL AND created_at < ?", 1.week.ago).order("last_liked_at DESC").includes(:user).limit(9)
      @liked_trips_and_albums = (liked_trips + liked_albums).sort{ |a,b| a.last_liked_at <=> b.last_liked_at }.reverse[0..8]
      @liked_trip_and_album_groups = @liked_trips_and_albums.in_groups_of(3)

      @liked_photos = Photo.where("last_liked_at IS NOT NULL AND created_at < ?", 1.week.ago).order("last_liked_at DESC").includes(:user).includes(:title_places).limit(9)
    end

    unless read_fragment(:part => 'comments')
      commented_trips = TripReport.where("last_comment_at IS NOT NULL").includes(:user).order("last_comment_at DESC").limit(4)
      commented_albums = Album.where("last_comment_at IS NOT NULL").order("last_comment_at DESC").includes(:user).limit(4)
      @commented_trips_and_albums = (commented_trips + commented_albums).sort{ |a,b| a.last_comment_at <=> b.last_comment_at }.reverse[0..3]
      @commented_photos = Photo.where("last_comment_at IS NOT NULL").order("last_comment_at DESC").limit(4)
    end

    displayCustomDataForSignedInUsers
    logVisit

    if user_is_admin? #I want to know who visited last on this screen
      add_stats_to_notice User
      add_stats_to_notice IpAddress
    end

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def updated
    @noindex = true #Don't let search engines index this page
    unless read_fragment(:part => 'trips_and_albums')
      trip_reports = TripReport.where("update_id IS NOT NULL").order("updated_at DESC").limit(9)
      albums = Album.where("update_id IS NOT NULL AND deleted = false").order("updated_at DESC").limit(9)
      #Combine trips and albums into one array.
      @trips_and_albums = (trip_reports + albums).sort{ |a,b| a.updated_at <=> b.updated_at }.reverse[0..8]
      @trip_and_album_groups = @trips_and_albums.in_groups_of(3)
    end

    unless read_fragment(:part => 'photos')
      @photo_users = User.joins('inner join photos on users.id = photos.user_id').where('photos.updated_at > ?', 4.months.ago).group('users.id').order('MAX(photos.updated_at) DESC').limit(5)
    end
    @place_groups = Place.where("update_id IS NOT NULL").order("updated_at DESC").limit(12).in_groups_of(4) unless read_fragment(:part => 'places')
    @route_groups = Route.where("update_id IS NOT NULL").order("updated_at DESC").limit(9).in_groups_of(3) unless read_fragment(:part => 'routes')

    displayCustomDataForSignedInUsers
    logVisit

    respond_to do |format|
      format.html # updated.html.erb
    end

  end

  # Gets a listing of site links in case people don't like using the search bar.
  def listing
    @noindex = true #Don't let search engines index this page
    respond_to do |format|
      format.html { render :layout => 'nomenu' } # listing.html.erb
    end
  end

  #Expires the cache fragments in the index method
  def expire_index
    Rails.cache.clear("menu")
    expire_fragment(:action => "index", :part => "trips_and_albums")
    expire_fragment(:action => "index", :part => "trips_and_albums_count")
    expire_fragment(:action => "index", :part => "photos")
    expire_fragment(:action => "index", :part => "photos_count")
    expire_fragment(:action => "index", :part => "places")
    expire_fragment(:action => "index", :part => "routes")
    expire_fragment(:action => "index", :part => "users")
    expire_fragment(:action => "index", :part => "liked")
    expire_fragment(:action => "index", :part => "comments")
    respond_to do |format|
      format.html { redirect_to(root_path, :notice => 'Main index cache was cleared.') }
      format.xml  { head :ok }
    end
  end

  def gmap
    @noindex = true #Don't let search engines index this page
    @google_map = true
    begin
      setup_gmap
      #Only cache based off the area. That way there are less pages to cache.
      unless params[:radius].blank? && read_fragment(:part => "map_places#{@lat.to_s},#{@lon.to_s}")
        @places = Place.find_by_radius(@lat, @lon, @radius, 0).includes(:border_points)#Km
      end #cache google_map_places
    rescue ActiveRecord::RecordNotFound
	logger.error "Attempt to access invalid record #{params[:id]}"
	redirect_to places_path, :notice => "Invalid record"
    else
    	respond_to do |format|
      	  format.html { render :layout => 'nomenu' } # show.html.erb
	end
    end
  end

  #Expires the cache fragments in the gmap action for the given lat/lon
  #Note it doesn't expire the form fragment.
  def expire_gmap
    begin
      setup_gmap
      expire_fragment(:action => "gmap", :part => "map_places#{@lat.to_s},#{@lon.to_s}")
      Place.find_by_radius(@lat, @lon, @radius, 0).each do |place|
    	expire_fragment(:controller => "places", :action => "infowindow", :id => place.to_param, :part => "infowindow_0")
      end
    rescue ActiveRecord::RecordNotFound
      logger.error "Attempt to access invalid record #{params[:id]}"
      redirect_to places_path, :notice => "Invalid record"
    else
      params.delete "action"
      respond_to do |format|
        format.html { redirect_to(gmap_path(params), :notice => 'Gmap cache was cleared.') }
      end
    end
  end

  def search
    @noindex = true #Don't let search engines index this page
    @search_text = Riddle::Query.escape(params[:search])

    field_weights = {
	:name => 50,
	:title => 5
    }

    @results = ThinkingSphinx.search(@search_text, :page=>1, :per_page => 100, :classes => [Place], :order => "importance desc", :field_weights => field_weights)

    if(Mountain::SEARCH_KEY_WORDS.any? {|word| @search_text.downcase.include?(word)})
      #Remove search key words so that the new search can match more mountains.
      new_search = @search_text.downcase.gsub(Regexp.union(Mountain::SEARCH_KEY_WORDS), '')
      @results = ThinkingSphinx.search("\"#{@search_text}\" | \"#{new_search}\"", :page=>1, :per_page => 100, :classes => [Mountain], :order => "importance desc", :field_weights => field_weights) | @results

    elsif(Lake::SEARCH_KEY_WORDS.any? {|word| @search_text.downcase.include?(word)})
      #Remove search key words so that the new search can match more mountains.
      new_search = @search_text.downcase.gsub(Regexp.union(Lake::SEARCH_KEY_WORDS), '')
      @results = ThinkingSphinx.search("\"#{@search_text}\" | \"#{new_search}\"", :page=>1, :per_page => 100, :classes => [Lake], :order => "importance desc", :field_weights => field_weights) | @results
    end


    @results = @results | ThinkingSphinx.search(@search_text, :page=>1, :per_page => 100, :field_weights => field_weights)

    if params[:open_best_result].blank? || params[:open_best_result] == "on"
      #bestValue = 0
      bestResult = @results.first
      unless bestResult.nil?
        redirect_to bestResult, :notice => help.link_to("See other results for `#{params[:search]}'", search_path(:search => params[:search], :open_best_result => "off"))
      end
      return unless bestResult.nil?
    end
    respond_to do |format|
      format.html
      format.json
    end
  end

  private

  #Used by index, everything
  def getNewTripsAndAlbums
    unless read_fragment(:part => 'trips_and_albums')
      trip_reports = TripReport.order("created_at DESC").includes(:user).includes(:route).limit(9)
      albums = Album.where("deleted=false").includes(:user).order("created_at DESC").limit(9)
      #Combine trips and albums into one array.
      @trips_and_albums = (trip_reports + albums).sort{ |a,b| a.created_at <=> b.created_at }.reverse[0..8]
      @trip_and_album_groups = @trips_and_albums.in_groups_of(3)
    end
    unless read_fragment(:part => 'trips_and_albums_count')
      numTripReportsToday = TripReport.where("created_at > :time", :time => (Time.now-1.day)).count
      numTripReportsThisWeek = TripReport.where("created_at > :time", :time => (Time.now-1.week)).count
      numAlbumsToday = Album.where("created_at > :time AND deleted=false", :time => (Time.now-1.day)).count
      numAlbumsThisWeek = Album.where("created_at > :time AND deleted=false", :time => (Time.now-1.week)).count
      @numTripsAlbumsToday = numTripReportsToday+numAlbumsToday
      @numTripsAlbumsThisWeek = numTripReportsThisWeek + numAlbumsThisWeek 
    end
  end

  #Used by index, everything
  def getNewPhotos
    unless read_fragment(:part => 'photos')

      @photo_users = User.joins('inner join photos on users.id = photos.user_id').where('photos.created_at > ?', 4.months.ago).group('users.id').order('MAX(photos.created_at) DESC').limit(5)
    end
    unless read_fragment(:part => 'photos_count')
      @numPhotosToday = Photo.where("created_at > :time", :time => (Time.now-1.day)).count
      @numPhotosThisWeek = Photo.where("created_at > :time", :time => (Time.now-1.week)).count
    end
  end

  #Display custom information for the user if they are signed in.
  #Also record their http_user_agent and access time
  def displayCustomDataForSignedInUsers
    if user_signed_in?
#      if current_user.recentGrantedAccessTime != 0
#        flash.now[:notice] = "" if flash.now[:notice].nil?
#        flash.now[:notice] += " Congratulations! You have been granted #{help.distance_of_time_in_words(Time.now, Time.now + current_user.recentGrantedAccessTime)} of access time for recommendations of content you submitted. See the #{ help.link_to("contribution guide", contributions_path)} for more information."
#        current_user.recentGrantedAccessTime = 0
#      end

      if !current_user.notifications.nil?
        flash.now[:notice] = "" if flash.now[:notice].nil?
        flash.now[:notice] += " " + current_user.notifications
        current_user.notifications = nil
      end

      if !current_user.last_visit_at.nil?
        numTripReportsSinceLastVisit = TripReport.where("created_at > :time", :time => current_user.last_visit_at).count
        numAlbumsSinceLastVisit = Album.where("created_at > :time AND deleted=false", :time => current_user.last_visit_at).count
	@numTripsAlbumsSinceLastVisit = numTripReportsSinceLastVisit + numAlbumsSinceLastVisit
        @numPhotosSinceLastVisit = Photo.where("created_at > :time", :time => current_user.last_visit_at).count
      end

      current_user.last_visit_at = Time.now
      current_user.last_http_user_agent = request.user_agent
      current_user.save
    end

  end

  #For admins show user/ip_address
  def add_stats_to_notice stat_class
    column = stat_class == User ? 'id' : 'user_id'
    plural = stat_class.to_s.tableize
    last_visitors = stat_class.where("(#{column} != ? OR #{column} IS NULL) AND last_visit_at IS NOT NULL", current_user.id).order("last_visit_at DESC").limit(5)
    last_visitors = last_visitors.includes(:user) if stat_class == IpAddress
    flash.now[:notice] = '' if flash.now[:notice].nil?
    flash.now[:notice] += 'Latest Visitors: '
    last_visitors.each do |visitor|
      flash.now[:notice] += help.link_to(visitor.display_name, send(stat_class.to_s.tableize.singularize + "_path", visitor.id)) + " #{help.distance_of_time_in_words(visitor.last_visit_at, Time.now)} ago, " unless visitor.last_visit_at.blank?
    end
    flash.now[:notice] = flash.now[:notice][0..-3] + "<br>"
  end

  #Used by gmap and expire_gmap. Get the radius, center lat/lon for the gmap.
  def setup_gmap
    @radius = 100
    @centerLatitude = 0
    @centerLongitude = 0
    if(!params[:place_id].blank?)
      @article = Place.find(params[:place_id])
      @title = "Google map view of #{@article.name} and surrounding area"
      @centerLatitude = @article.centerLatitude
      @centerLongitude = @article.centerLongitude
    elsif(!params[:photo_id].blank?)
      @article = Photo.find(params[:photo_id])
      @title = "Google map view of the area where the photo was taken"
      @centerLatitude = @article.lat_for_map
      @centerLongitude = @article.lon_for_map
    elsif(!params[:route_id].blank?)
      @article = Route.find(params[:route_id])
      @title = "Google map view of the route and surrounding area"
      @centerLatitude = @article.averageLatitude
      @centerLongitude = @article.averageLongitude
    elsif(!params[:trip_report_id].blank?)
      @article = TripReport.find(params[:trip_report_id])
      @title = "Google map view of the route and surrounding area"
      @centerLatitude = @article.route.averageLatitude
      @centerLongitude = @article.route.averageLongitude
    elsif(!params[:album_id].blank?)
      @article = Album.find(params[:album_id])
      @title = "Google map view of the area where the album was taken"
      @centerLatitude = @article.ref_latitude
      @centerLongitude = @article.ref_longitude
    end
    @radius = params[:radius].to_i unless params[:radius].blank?
    @radius = 300 if @radius > 300 #Don't do higher than 300
    @radius = 40 if @radius < 40 #Don't do less than 40
    @lat = @centerLatitude.round
    @lon = @centerLongitude.round
  end
end
