class PlacesController < ApplicationController 
  skip_before_filter :authenticate_user!, :only => [:infowindow, :place_search,:photos]
  skip_before_filter :editor_required, :only => [:infowindow, :place_search,:expire_desc,:photos]
  skip_before_filter :admin_required, :only => [:infowindow, :place_search,:expire_desc,:photos]

  caches_action :index, :expires_in => 1.year, :cache_path => Proc.new { |c| c.params }

  def index
    @noindex = true #Don't let search engines index this page
    begin
      @record_class = params[:type].blank? ? Place : Place.subclasses.find{|subclass| subclass.to_s == params[:type]}
      @parent_class = Place
      @page = params[:page]
      @place_id = ''
      if @record_class.present? && (@record_class.superclass == Place || @record_class == Place)
        @sort = params[:sort].blank? ? @record_class::DEFAULT_SORT : params[:sort]
        @lower = params[:lower].blank? ? nil : params[:lower]#Lower alphabetical starting point
        @upper = params[:upper].blank? ? nil : params[:upper]#Upper alphabetical starting point
        if params[:place_id].blank?
          @records = @record_class.list(@sort, @lower, @upper).includes(:areas).paginate :page=>params[:page]
        else
          @place = Place.find(params[:place_id])
	  @place_id = @place.id
          if @record_class == Mountain
	    @records = @place.mountains.joins(:detail)
	  else
            @records = @place.get_places_of_type(@record_class)
	  end
	  @records = @records.order(@record_class::SORT_OPTIONS[@sort]).paginate :page=>params[:page]
        end

        @type = @record_class.to_s.titleize
        @type_tag = params[:type]
      else
        redirect_to(root_path)
        return
      end
    rescue ActiveRecord::RecordNotFound
      logger.error "Attempt to access invalid place #{params[:place_id]}"
      redirect_to places_path, :notice => "Invalid place"
    else
      respond_to do |format|
        format.html { render :template => "all/index" }
        format.xml  { render :xml => @records }
      end
    end
  end

  def show
    begin
      @place = Place.find(params[:id])
      if @place.slug != params[:id] && @place.slug.present?
        redirect_to(@place, :status => :moved_permanently)
        return
      end

      logVisit @place

      @pageTitle = @place.name
      @metaDescription = @place.description.blank? ? @place.name : @place.description
      @title_photo = @place.title_photo #if @place.area < Place::MAX_AREA_FOR_TITLE_ARTICLES
      @type = @place.class.to_s.titleize
      @google_map = true
      @first_area_id = @place.areas.count == 0 ? nil : @place.areas.first.id
    
      @centerLatitude = @place.centerLatitude
      @centerLongitude = @place.centerLongitude
      @zoom = @place.centerLatitude < 60 ? 13 : @place.centerLatitude < 80 ? 11 : 4
      @title_photo = @place.title_photo
      
      unless @place.class != Mountain || read_fragment(:part => "description_#{@place.id}")
        @parent_mountain = @place.parent_mountain.present? ? @place.parent_mountain : @place.highest_subpeak.parent_mountain
        @dist_to_parent = @place.parent_mountain.present? ? @place.dist_to_parent : @place.highest_subpeak.dist_to_parent
      end

      unless read_fragment(:part => "nearby_places_#{@place.id}")
        @has_photos = @place.title_photos.count != 0
        @nearby_places_without_photos = @place.places_nearby_without_photos(22)
        @num_nearby_places_without_photos = @nearby_places_without_photos.count
        @num_nearby_peaks_without_photos = @nearby_places_without_photos.where("places.type = 'Mountain'").count
        @has_nearby_places_without_photos = @title_photo || @nearby_places_without_photos.count != 0 
        @nearby_places_without_photos = @nearby_places_without_photos.limit(20)
      end

      unless read_fragment(:part => "routes_#{@place.id}")
        @routes = @place.routes.includes(:user)
        @has_routes = @routes.count != 0
      end
      unless read_fragment(:part => "trip_reports_#{@place.id}")
        @trip_reports = @place.trip_reports
        @has_trip_reports = @trip_reports.count != 0
        @trip_groups = @trip_reports.in_groups_of(1) if @trip_reports.count == 1
        @trip_groups = @trip_reports.in_groups_of(2) if @trip_reports.count > 1
        @trip_groups = @trip_reports.in_groups_of(3) if @trip_reports.count > 4
      end
      unless read_fragment(:part => "albums_#{@place.id}")
        @albums = @place.title_albums + @place.albums_in_area.where('deleted=false')
        @has_albums = @albums.count != 0
        @album_groups = @albums.in_groups_of(1) if @albums.count == 1
        @album_groups = @albums.in_groups_of(2) if @albums.count > 1
        @album_groups = @albums.in_groups_of(3) if @albums.count > 4
        @album_appearances = @place.album_appearances.where('deleted=false')
        @appears_in_other_albums = @album_appearances.count != 0
        @album_appearances_groups = @album_appearances.in_groups_of(1) if @album_appearances.count == 1
        @album_appearances_groups = @album_appearances.in_groups_of(2) if @album_appearances.count > 1
        @album_appearances_groups = @album_appearances.in_groups_of(3) if @album_appearances.count > 4
      end
    
      unless read_fragment(:part => "google_map_#{@place.id}")
        @places = @place.mountains.order_by_isolation.limit(50)
	@places += @place.huts
        @places += @place.places.includes(:border_points).without_mountains_huts.order('height').limit(20)
        @has_places = @places.count != 0
      end

      unless read_fragment(:part => "photos_#{@place.id}")
        @photos = @place.title_photos.includes(:user)
        @photos = @photos.order("COALESCE(photos.total_likes,0) DESC")
        @has_photos = @photos.count != 0
        @photo_appearances = @place.photo_appearances.includes(:user)
        @appears_in_other_photos = @photo_appearances.count != 0
      end

    rescue ActiveRecord::RecordNotFound
      redirect_to search_path(:search => params[:id].gsub("-"," "), :open_best_result => "on")
    else
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @place }
      end
    end

  end

  #Expires the cache fragments in the show method
  def expire
    if params[:id].blank?
      expire_index
    else
      @place = Place.find(params[:id])
      expire_fragment(:action => "photos", :part => "photos_#{@place.id}")
      expire_fragment(:action => "show", :part => "photos_#{@place.id}")
      expire_fragment(:action => "photos", :part => "other_photos_#{@place.id}")
      expire_fragment(:action => "show", :part => "routes_#{@place.id}")
      expire_fragment(:action => "show", :part => "trip_reports_#{@place.id}")
      expire_fragment(:action => "show", :part => "albums_#{@place.id}")
      expire_fragment(:action => "show", :part => "google_map_#{@place.id}")
      expire_fragment(:action => :show, :part => "nearby_places_#{@place.id}")
      expire_fragment(:action => "show", :part => "description_#{@place.id}")
      expire_fragment(:action => :show, :part => "infowindow_#{@place.id}")
      respond_to do |format|
        format.html { redirect_to(@place, :notice => 'Place cache was cleared.') }
        format.xml  { head :ok }
      end
    end
  end

  #Expires the description fragment in the show method
  def expire_desc
    @place = Place.find(params[:id])
    expire_fragment(:action => "show", :part => "description_#{@place.id}")
    expire_fragment(:action => :show, :part => "nearby_places_#{@place.id}")
    respond_to do |format|
      format.html { redirect_to(@place, :notice => 'Place description was cleared.') }
      format.xml  { head :ok }
    end
  end

  #Returns partial html with photo thumbs. Requested by jquery after page scroll
  def photos
    @place = Place.find(params[:id])
     
    unless read_fragment(:part => "photos_#{@place.id}")
      @photos = @place.title_photos.includes(:user).includes(:title_places)
      @has_photos = @photos.length != 0
      @photo_appearances = @place.photo_appearances.includes(:user).includes(:title_places)
      @appears_in_other_photos = @photo_appearances.length != 0
    end
    unless read_fragment(:part => "other_photos_#{@place.id}")
      @photos_in_area = @place.photos_in_area.includes(:user).limit(200)
      @has_photos_in_area = @photos_in_area.length != 0
    end

#    if request.user_agent.downcase.include? "google"
#      UserMailer.notify_admins("Place photos for #{@place.name} has been requested by a google bot").deliver
#    end

    respond_to do |format|
      format.html { render :layout => false}
      format.xml  { render :xml => @user }
    end
  end

  def new
    params[:type] = params[:type].delete(' ')
    place_class = params[:type] == "Place" ? Place : Place.subclasses.find{|subclass| subclass.to_s == params[:type]}
    if (place_class.superclass == Place && !params[:ref_place_id].blank?)
      @place = place_class.new
    else
      redirect_to(root_path)
      return
    end
    @place.ref_place_id = params[:ref_place_id]
    ref_place = Place.find(params[:ref_place_id])
    @startLatitude = ref_place.centerLatitude
    @startLongitude = ref_place.centerLongitude
    @title = ref_place.name

    #New places are assumed to be unofficial by default.
    @place.name_status = "Unofficial"

    if current_user.id == 1 && @place.class == Mountain
      @place.height_reference = Place::HEIGHT_SOURCE_TYPES[:TopoMap]
    else
      @place.height_reference = Place::HEIGHT_SOURCE_TYPES[:Google]
    end

    if current_user.id == 1 && @place.class == Waterfall
      @place.name_reference = Place::NAME_SOURCE_TYPES[:WaterfallIceClimbs]
    end

    @type = @place.class.to_s.titleize
    @zoom = 10
    @google_map = true
    @submit = "Create #{@type}"

    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @place }
    end
  end

  def edit
    @place = Place.find(params[:id])
    @type = @place.class.to_s.titleize
    @google_map = true
    @startLatitude = @place.centerLatitude
    @startLongitude = @place.centerLongitude
    @title = "Current Coordinates"
    @zoom = 10
    @submit = "Update #{@type}"

    if current_user.id == 1 && (@place.name_reference == Place::NAME_SOURCE_TYPES[:Canada] || @place.name_reference == Place::NAME_SOURCE_TYPES[:States])
      @place.name_reference = Place::NAME_SOURCE_TYPES[:TopoMap]
    end

    if current_user.id == 1 && @place.class == Mountain && @place.height_reference == Place::HEIGHT_SOURCE_TYPES[:Google]
      @place.height_reference = Place::HEIGHT_SOURCE_TYPES[:TopoMap]
    end

    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @place }
    end
  end

  def create
    place_class = params[:place][:type] == "Place" ? Place : Place.subclasses.find{|subclass| subclass.to_s == params[:place][:type]}
    if (place_class.present?)
      @place = place_class.new(place_params)
    else
      redirect_to(root_path)
      return
    end
    @place.insert_id = current_user.id
    @type = @place.type.to_s.titleize
    if !params[:upload].blank?#kml file ?
      if params[:upload]['datafile'].original_filename.ends_with? '.kml'
        content = params[:upload]['datafile'].read
        coordinate_index = content.index('<coordinates>') + '<coordinates>'.length
        coordinates = content[coordinate_index .. content.index('</coordinates>', coordinate_index)-1]
	#For some reason the first coordinate is half at the start and half at the end. Need to fix first.
	firstLongitude = coordinates[0 .. coordinates.index(',')-1]
	coordinates = coordinates[coordinates.index(',')+1 .. coordinates.length-1]
	coordinates +=  ' ' + firstLongitude
	@place.addPoints coordinates
      end
    end

    notice = "#{@type} was successfully created."
    respond_to do |format|
      if @place.save
        after_create()
        format.html { redirect_to(@place, :notice => notice) }
        format.xml  { render :xml => @place, :status => :created, :location => @place }
      else
    	@place.ref_place_id = params[:place][:ref_place_id]
        ref_place = Place.find(params[:place][:ref_place_id])
        @startLatitude = ref_place.centerLatitude
        @startLongitude = ref_place.centerLongitude
        @title = ref_place.name
	@zoom = 10
        @google_map = true
        @submit = "Create #{@type}"

        #New places are assumed to be unofficial by default.
        @place.name_status = "Unofficial"

	format.html { render :action => "new", :type => @place.type, :layout => 'nomenu' }
        format.xml  { render :xml => @place.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @place = Place.find(params[:id])
    @place.update_id = current_user.id
    @type = params[:place][:type].titleize
    @place.type = params[:place][:type]
    @place.update_id = current_user.id
    
    respond_to do |format|
      if @place.update_attributes(place_params)
	if @place.user != current_user && current_user.id != 1
          UserMailer.notify_admins("Place: #{@place.name} has been updated by #{current_user.display_name}").deliver
	end
	after_update()
        format.html { redirect_to(@place, :notice => "#{@type} was successfully updated.") }
        format.xml  { head :ok }
      else
        @google_map = true
        @startLatitude = @place.centerLatitude
        @startLongitude = @place.centerLongitude
        @title = "Current Coordinates"
        @submit = "Update #{@type}"
        format.html { render :action => "edit", :layout => 'nomenu' }
        format.xml  { render :xml => @place.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
#    @place = Place.find(params[:id])
#    @place.destroy
    UserMailer.notify_admins_critical("Place: #{@place.name} has been deleted by #{current_user.display_name}").deliver

    respond_to do |format|
      format.html { redirect_to(places_url(:type => @place.type)) }
      format.xml  { head :ok }
    end
  end

  #Search for places within this place if it has an area
  def place_search
    @places = []
    area = params[:area_id].blank? ? nil : Place.find(params[:area_id])
    if area.present? && area.area > 0
      search_text = Riddle::Query.escape(help.strip_links(params[:search]))
      results = Place.search(search_text, :field_weights => { :name => 10 })

      results.each do |place|
        @places << place if place.areas.include?(area)
      end
    end
    
    respond_to do |format|
      format.json
    end
  end

  def infowindow
    @place_id = params[:id].to_i
    unless read_fragment(:part => "infowindow_#{@place_id}")
      @place = Place.find(params[:id])
    end
    respond_to do |format|
      format.html { render :layout => false}
    end
  end

  private

  def place_params
    params.require(:place).permit(:name, :name_status, :name_reference, :type, :ref_place_id, :alternate_names, :sub_region, :description, :height, :height_reference, :latitude, :longitude, :match_names, :reject_names, :references, :names_attributes => [:id, :name, :year, :person_id, :named_by_other, :named_after_person_id, :description, :_destroy], :border_points_attributes => [:id, :latitude, :longitude, :local_index, :_destroy], :ascents_attributes => [:id, :year, :month, :day, :ascent_index, :winter_ascent_index, :success, :solo, :route_id, :route_ascent_index, :description, :other_participants, :_destroy, :ascent_people_attributes => [:id, :person_id, :_destroy]])
  end

  def after_save
    if @place.name_changed?
      @place.places.each do |place|
        expire_fragment(:controller=>"places", :action=>"show", :id => place, :part => "description_#{place.id}")
      end
      @place.routes.each do |route|
        expire_fragment(:controller=>"routes", :action=>"show", :id => route, :part => "description_#{route.id}")
      end
    end

    @place.areas.each do |area|
      expire_fragment(:controller=>"places", :action=>"show", :id => area, :part => "description_#{area.id}")
      expire_fragment(:controller=>"places", :action=>"show", :id => area, :part => "google_map_#{area.id}")
    end

  end

  # If we create a new place, the public list of place must be regenerated
  def after_create
    (@place.class::SORT_OPTIONS.keys+[nil]).each do |sort|
      expire_fragment(send("#{@place.class.to_s.tableize}_url", :sort => sort).gsub("http://", ""))
      (@place.area_ids + [nil]).each do |area_id|
        expire_fragment(:controller=>"places", :action=>"index", :sort => sort, :area_id => area_id)
      end
    end
    expire_fragment(:controller => 'main', :action => 'index', :part => 'places')

    after_save()
  end

  # If we update an existing place, the public list of updated places must be regenerated
  def after_update
    expire_fragment(:controller => 'main', :action => 'updated', :part => 'places')
    expire_fragment(:controller=>"places", :action=>"show", :id => @place, :part => "google_map_#{@place.id}")
    expire_fragment(:controller=>"places", :action=>"show", :id => @place, :part => "description_#{@place.id}")
    expire_fragment(:controller=>"places", :action=>"infowindow", :id => @place, :part => "infowindow_#{@place.id}")

    if @place.name_changed?
      @place.routes.each do |route|
        expire_fragment(:controller=>"routes", :action=>"show", :id => route, :part => "description_#{route.id}")
        route.trip_reports.each do |trip_report|
          expire_fragment(:controller=>"trip_reports", :action=>"show", :id => trip_report, :part => "description_#{trip_report.id}")
        end
      end
    end

    after_save()
  end

end
