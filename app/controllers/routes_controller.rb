class RoutesController < ApplicationController 
  skip_before_filter :authenticate_user!, :only => [:photos]
  skip_before_filter :editor_required, :only => [:edit, :update, :new, :create, :photos]
  before_filter :edit_permission_required, :except => [:index, :show, :new, :create, :destroy, :expire, :photos]
  skip_before_filter :admin_required, :only => [:photos]
  
  caches_action :index, :expires_in => 3.months, :cache_path => Proc.new { |c| c.params }

  # GET /routes
  # GET /routes.xml
  def index
    @noindex = true #Don't let search engines index this page
    #@record_class = params[:type].blank? ? Route : params[:type].to_s.constantize
    @record_class = params[:type].blank? ? Route : Route.subclasses.find{|subclass| subclass.to_s == params[:type]}
    @parent_class = Route
    if (@record_class.superclass == Route || @record_class == Route)
      @sort = params[:sort].blank? ? @record_class::DEFAULT_SORT : params[:sort]
      @lower = params[:lower].blank? ? nil : params[:lower]#Lower alphabetical starting point
      @upper = params[:upper].blank? ? nil : params[:upper]#Upper alphabetical starting point
      @records = @record_class.list(@sort, @lower, @upper).includes(:user).includes(:areas).paginate :page=>params[:page]
      @type = @record_class.to_s.titleize
      @type_tag = params[:type]
    else
      redirect_to(root_path)
      return
    end
    respond_to do |format|
      format.html { render :template => "all/index" }
      format.xml  { render :xml => @records }
    end
  end

  # GET /routes/1
  # GET /routes/1.xml
  def show
    @route = Route.find(params[:id])
    logVisit @route
    @pageTitle = @route.name
    @metaDescription = @route.description.blank? ? @route.name : @route.description
    @type = @route.class.to_s.titleize
    @show_edit_link = can_edit?
    @has_map = false
    if(@route.waypoints.length > 0)
      @google_map = true
      @has_map = true
      @centerLatitude = @route.averageLatitude
      @centerLongitude = @route.averageLongitude
    end
    @first_area_id = @route.areas.count == 0 ? nil : @route.areas.first.id
    @dist = @route.distance
    @gain = @route.height_gain
    @loss = @route.height_loss

    unless read_fragment(:part => "trip_reports_#{@route.id}")
      @trip_reports = @route.trip_reports.paginate :page=>params[:page], :per_page => 15
      @has_trip_reports = @trip_reports.length != 0
      @trip_groups = @trip_reports.in_groups_of(1) if @trip_reports.length == 1
      @trip_groups = @trip_reports.in_groups_of(2) if @trip_reports.length > 1
      @trip_groups = @trip_reports.in_groups_of(3) if @trip_reports.length > 4
    end

    unless read_fragment(:part => "albums_#{@route.id}")
      @albums = @route.albums.paginate :page=>params[:page], :per_page => 15
      @has_albums = @albums.length != 0
      @album_appearances = @route.album_appearances.paginate :page=>params[:page], :per_page => 20
      @appears_in_other_albums = @album_appearances.length != 0
    end

    unless read_fragment(:part => "photos_#{@route.id}")
      @photos = @route.photos.paginate :page=>params[:page], :per_page => 50
      @has_photos = @photos.length != 0
      @photo_appearances = @route.photo_appearances.paginate :page=>params[:page], :per_page => 20
      @appears_in_other_photos = @photo_appearances.length != 0
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @route.to_xml(:include => [:waypoints, :trip_reports]) }
    end
  end

  #Expires the cache fragments in the show method
  def expire
    if params[:id].blank?
      expire_index
    else
      @route = Route.find(params[:id])
      expire_fragment(:action => "photos", :part => "photos_#{@route.id}")
      expire_fragment(:action => "show", :part => "photos_#{@route.id}")
      expire_fragment(:action => "show", :part => "trip_reports_#{@route.id}")
      expire_fragment(:action => "show", :part => "albums_#{@route.id}")
      expire_fragment(:action => "show", :part => "description_#{@route.id}")
      expire_fragment(:action => "show", :part => "google_map_#{@route.id}")
      respond_to do |format|
        format.html { redirect_to(@route, :notice => 'Route cache was cleared.') }
        format.xml  { head :ok }
      end
    end
  end

  #Expires the description fragment in the show method
  def expire_desc
    @route = Route.find(params[:id])
    expire_fragment(:action => "show", :part => "description_#{@route.id}")
    respond_to do |format|
      format.html { redirect_to(@route, :notice => 'Route cache was cleared.') }
      format.xml  { head :ok }
    end
  end

  #Returns partial html with photo thumbs. Requested by jquery after page load
  def photos
    @route = Route.find(params[:id])

    unless read_fragment(:part => "photos_#{@route.id}")
      @photos = @route.photos.paginate :page=>params[:page], :per_page => 50
      @has_photos = @photos.length != 0
      @photo_appearances = @route.photo_appearances.paginate :page=>params[:page], :per_page => 20
      @appears_in_other_photos = @photo_appearances.length != 0
    end

#if request.user_agent.downcase.include? "google"
#      UserMailer.notify_admins("Route photos for #{@route.name} has been requested by a google bot").deliver
#    end

    respond_to do |format|
      format.html { render :layout => false}
      format.xml  { render :xml => @user }
    end
  end


  # GET /routes/new
  # GET /routes/new.xml
  def new
    #route_class = params[:type].constantize
    params[:type] = params[:type].delete(' ')
    route_class = params[:type] == "Route" ? Route : Route.subclasses.find{|subclass| subclass.to_s == params[:type]}
    if (route_class == Route || route_class.superclass == Route)
      @route = route_class.new
    else
      redirect_to(root_path)
      return
    end
    @type = route_class.to_s.titleize
    setup_new
    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { 
	if @trip
	  render :xml => @trip_report.to_xml(:include => {:route => {:include => :waypoints}})
	else
	  render :xml => @route.to_xml(:include => :waypoints)
	end
      }
    end
  end

  # GET /routes/1/edit
  def edit
    @route = Route.find(params[:id])
    @type = @route.type.to_s.titleize
    setup_edit
    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  {
	if @trip
	  render :xml => @trip_report.to_xml(:include => {:route => {:include => :waypoints}})
	else
	  render :xml => @route.to_xml(:include => :waypoints)
	end
      }
    end
  end

  # POST /routes
  # POST /routes.xml
  def create
    clean_up_waypoint_indices #Cleans up indices that are wrong due to removed points
    route_class = params[:route][:type].blank? || params[:route][:type] == "Route" ? Route : Route.subclasses.find{|subclass| subclass.to_s == params[:route][:type]}
    if (route_class.present?)
      @route = route_class.new(route_params)
    else
      redirect_to(root_path)
      return
    end
    @route.insert_id = current_user.id
    @route.travel_time = "Unknown";
    @type = @route.class.to_s.titleize
    @route.type = @route.class.to_s
    success_notice = "#{@type} was successfully created."

    loadWaypointsFromFile #If a file is present
    
    @route.trip_reports.each do |trip_report|
      trip_report.user_id = current_user.id
      success_notice = "Trip report and #{@type} were successfully created."
    end

    respond_to do |format|
      if @route.save

        after_create()
        if @route.trip_reports.count > 0
          params[:photo_ids] = "" if params[:photo_ids].nil? 
          @route.trip_reports.each do |trip_report|
            Photo.find(params[:photo_ids].split(",")).each do |photo|
              photo.update_attributes(:trip_report_id => trip_report.id)
            end
	  end
          format.html { redirect_to(@route.trip_reports.first, :notice => success_notice) }
          format.xml  { render :xml => @route.trip_reports.first, :status => :created, :location => @route.trip_reports.first }
	else
          format.html { redirect_to(@route, :notice => success_notice) }
          format.xml  { render :xml => @route, :status => :created, :location => @route }
	end
      else #Something failed validation. Create variables for new action and render new
        #puts "Erros: (#{@route.errors.messages})"
        setup_new
        if !params[:place_id].blank?
          format.html { render :action => "new", :place_id => params[:place_id], :type => params[:route][:type], :layout => 'nomenu' }
	else
          format.html { render :action => "new", :type => @route.type, :layout => 'nomenu' }
	end
        format.xml  { render :xml => @route.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /routes/1
  # PUT /routes/1.xml
  def update
    clean_up_waypoint_indices #Cleans up indices that are wrong due to removed points
    @route = Route.find(params[:id])
    #@type = params[:route][:type].titleize
    #@route.type = params[:route][:type]
    @route.update_id = current_user.id
    #notice_text = "#{@route.class.to_s} was successfully updated."

    loadWaypointsFromFile #If a file is present

    #trip = false
    #if !params[:trip_report_id].blank?
    #  trip = true
    #  @trip_report = TripReport.find(params[:trip_report_id])
    #  @trip_report.update_id = current_user.id
    #  @trip_report.updated_at = Time.now
    #  notice_text = "Trip Report and #{@route.class.to_s} were successfully updated."
    #  params[:trip_report] = params[:route][:trip_report]
    #  params[:route].delete :trip_report
    #end

    respond_to do |format|
      if @route.update_attributes(route_params)#) && (!trip || @trip_report.update_attributes(trip_report_params)) 
	if @route.user != current_user && current_user.id != 1
          UserMailer.notify_admins("Route: #{@route.name} has been updated by #{current_user.display_name}").deliver
	end

        after_update()
        format.html { redirect_to(@route, :notice => "#{params[:route][:type].titleize} was successfully updated.") }
        #format.html { redirect_to(trip ? @trip_report : @route, :notice => "#{@route.class.to_s} was successfully updated.") }
        format.xml  { head :ok }
      else
        setup_edit
        format.html { render :action => "edit", :layout => 'nomenu' }
        format.xml  { render :xml => @route.errors, :status => :unprocessable_entity }
      end
    end
  end

  def dup
    @route = Route.find(params[:id]).dup
    @type = @route.type.titleize
    Route.find(params[:id]).waypoints.each do |waypoint|
      waypointdup = waypoint.dup
      waypointdup.route_id = nil
      @route.waypoints << waypointdup
    end
    setup_new
    respond_to do |format|
      format.html { render :action => "new", :type => @route.type, :layout => 'nomenu' }
    end
  end

  # DELETE /routes/1
  # DELETE /routes/1.xml
  def destroy
#    @route = Route.find(params[:id])
#    @route.destroy
#    UserMailer.notify_admins_critical("Route: #{@route.name} has been deleted by #{current_user.display_name}").deliver

    respond_to do |format|
      format.html { redirect_to(routes_url(:type => @route.type)) }
      format.xml  { head :ok }
    end
  end

  protected

  #This requires remapping of parent_indices as well to point to the new local_indices properly
  #essentially some points were deleted and we need to reconnect everything properly.
  #Every point after a deleted point must have their local_index subtracted by 1.
  #So if a point is after 3 deleted points its local_index would be -3
  #The Google Map interface should have each points parent_index point to a non deleted point.
  #So we just need to update parent_indexs when the parent points local_index is updated.
  def clean_up_waypoint_indices
    return if params[:route][:waypoints_attributes].nil?
    i = 0
    while !params[:route][:waypoints_attributes][i.to_s].nil?
      local_index = params[:route][:waypoints_attributes][i.to_s][:local_index].to_i
      parent_index = params[:route][:waypoints_attributes][i.to_s][:parent_index].to_i
      if params[:route][:waypoints_attributes][i.to_s][:_destroy] == "true"
        j = 0
        while !params[:route][:waypoints_attributes][j.to_s].nil?
          local_index2 = params[:route][:waypoints_attributes][j.to_s][:local_index].to_i
          parent_index2 = params[:route][:waypoints_attributes][j.to_s][:parent_index].to_i
	  local_index2 += -1 if local_index2 > local_index
	  parent_index2 += -1 if parent_index2 > local_index
	  params[:route][:waypoints_attributes][j.to_s][:local_index] = local_index2
	  params[:route][:waypoints_attributes][j.to_s][:parent_index] = parent_index2
	  j += 1
        end
      end
      i += 1
    end
  end

  #If a gpx file has been supplied then load the waypoints from the file. Called from create and update.
  def loadWaypointsFromFile
    if !params[:route][:gps].blank? #gpx file ?
      if params[:route][:gps].original_filename.downcase.ends_with?('.gpx')
    	params[:route][:waypoints_attributes] = [] #Cannot have waypoints from both a file and params.
	params[:route].delete(:distance) #This is computed in the addWaypoints function
	params[:route].delete(:height_gain) #This is computed in the addWaypoints function
	params[:route].delete(:height_loss) #This is computed in the addWaypoints function
        content = params[:route][:gps].read
        coordinate_index = content.index('<trkseg>') + '<trkseg>'.length
        coordinates = content[coordinate_index .. content.index('</trkseg>', coordinate_index)-1]
	@route.addWaypoints coordinates
      end
    end
  end

  #Called by new and create
  def setup_new
    @allow_branches = @route.class::ALLOW_BRANCHES
    @zoomLevel = 12
    @difficulties = Hash[([Route]+Route.subclasses).map {|subclass| [subclass.to_s, subclass::DIFFICULTY_OPTIONS] }]
    if(!params[:place_id].blank?)
      @route.place_id = params[:place_id]
      place = Place.find(params[:place_id])
      @zoomLevel = 10 if place.area.present? && place.area > 1000
      @zoomLevel = 9 if place.area.present? && place.area > 5000
      @place_id = params[:place_id]
      @startLatitude = place.centerLatitude
      @startLongitude = place.centerLongitude
      @startContent = "Center point of #{place.name}"
      @startName = "Center point of #{place.name}"
    elsif(@route.waypoints.length > 0)
      @place_id = @route.place_id if defined? @route.place_id
      @startLatitude = @route.averageLatitude
      @startLongitude = @route.averageLongitude
      @startContent = @route.name
      @startName = @route.name
    end
    @google_map = true
    @submit = "Create #{@type}"
    @trip = false

    @ref_title = "New Trip Report"
    @ref_latitude = @startLatitude
    @ref_longitude = @startLongitude

    #If creating route with a trip report then build one trip report
    if(!params[:trip].blank? && params[:trip].to_s == "true")
      @trip = true
      @submit = "Create Trip Report and #{@type}"
      @trip_report = @route.trip_reports.build
      @route.name = "Trip route"
      @route.name_status = "Unofficial"
      @start_time = ""
      @end_time = ""
    elsif(@route.trip_reports.length == 1)#Called from create action
      @trip = true
      @submit = "Create Trip Report and #{@type}"
      @trip_report = @route.trip_reports.first
      @start_time = @trip_report.start_time.nil? ? "" : @trip_report.start_time.strftime("%B %d %Y at %I:%M%P")
      @end_time = @trip_report.end_time.nil? ? "" : @trip_report.end_time.strftime("%B %d %Y at %I:%M%P")
    end
  end

  #Called by edit and update
  def setup_edit
    @allow_branches = @route.class::ALLOW_BRANCHES
    @google_map = true
    @zoomLevel = 12
    @difficulties = Hash[([Route]+Route.subclasses).map {|subclass| [subclass.to_s, subclass::DIFFICULTY_OPTIONS] }]
    @startLatitude = @route.averageLatitude
    @startLongitude = @route.averageLongitude
    @startContent = "Average waypoint"
    @startName = "Average waypoint"
    @trip = false
    @submit = "Update #{@type}"
    @place_id = @route.place_id if @route.place_id.present?
    
    if(!params[:trip_report_id].blank?)
      @trip = true
      @submit = "Update Trip Report and #{@type}"
      @trip_report = @route.trip_reports.find(params[:trip_report_id])
      @start_time = @trip_report.start_time.nil? ? "" : @trip_report.start_time.strftime("%B %d %Y at %I:%M%P")
      @end_time = @trip_report.end_time.nil? ? "" : @trip_report.end_time.strftime("%B %d %Y at %I:%M%P")
      @multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
      @ref_title = @trip_report.route.name
      @ref_latitude = @startLatitude
      @ref_longitude = @startLongitude
      @id = params[:trip_report_id]
    end
  end
  
  def can_edit?
    @user = Route.find(params[:id]).user
    user_signed_in? && (current_user.is_editor? || current_user == @user)
  end
  
  def edit_permission_required
    can_edit? ? true : permission_denied
  end

  def route_params
    params.require(:route).permit(:name, :name_status, :type, :alternate_names, :difficulty, :newb, :avalanche_rating, :glacier_travel, :seracs, :rockfall, :river_crossing, :objective_hazard, :place_id, :different_start_end, :access, :equipment, :distance, :height_gain, :height_loss, :description, :match_names, :reject_names, :references, :names_attributes => [:id, :name, :year, :person_id, :named_by_other, :named_after_person_id, :description, :_destroy], :trip_reports_attributes => [:title, :start_time, :end_time, :travel_time, :abstract, :participants, :description], :waypoints_attributes => [:id, :latitude, :longitude, :local_index, :parent_index, :height, :distance, :height_gain, :height_loss, :title, :location, :difficulty, :description, :icon, :_destroy])
  end

  def trip_report_params
    params.require(:trip_report).permit(:title, :start_time, :end_time, :travel_time, :abstract, :participants, :description)
  end

  def after_save
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    if @route.created_at >= @route.class.order('created_at DESC').limit(Route.per_page)[-1].created_at
      (@route.class::SORT_OPTIONS.keys+[nil]).each do |sort|
        expire_fragment(:controller=>"routes", :action=>"index", :sort => sort)
        expire_fragment(send("#{@route.class.to_s.tableize}_url", :sort => sort).gsub("http://", ""))
      end
    end
    @route.areas.each do |area|
      expire_fragment(:controller=>"places", :action=>"show", :id => area, :part => "routes_#{area.id}")
      expire_fragment(:controller=>"places", :action=>"show", :id => area, :part => "trip_reports_#{area.id}")
    end
    unless @route.place_id.nil?
      expire_fragment(:controller=>"places", :action=>"show", :id => @route.place, :part => "routes_#{@route.place_id}")
    end
    @route.places.each do |place|
      expire_fragment(:controller=>"places", :action=>"show", :id => place, :part => "routes_#{place.id}")
    end
  end

  # If we create a new route, the public list of routes must be regenerated
  def after_create
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    expire_fragment(:controller => 'main', :action => 'index', :part => 'routes')

    after_save()
  end

  # If we update an existing route, the public list of updated routes must be regenerated
  # Places that list this route must be updated if its name or coordinates changed.
  def after_update
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    expire_fragment(:controller => 'main', :action => 'updated', :part => 'routes')
    expire_fragment(:controller=>"routes", :action=>"show", :id => @route, :part => "description_#{@route.id}")
    expire_fragment(:controller=>"routes", :action=>"show", :id => @route, :part => "google_map_#{@route.id}")
    
    @route.trip_reports.each do |trip_report|
      expire_fragment(:controller=>"trip_reports", :action=>"show", :id => trip_report, :part => "description_#{trip_report.id}")
      expire_fragment(:controller=>"trip_reports", :action=>"show", :id => trip_report, :part => "google_map_#{@route.id}")
    end
    
    after_save()
  end


end
