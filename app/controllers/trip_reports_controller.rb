class TripReportsController < ArticlesController
  skip_before_filter :editor_required, :only => [:multi_photos]
  skip_before_filter :admin_required, :only => [:multi_photos]

  caches_action :index, :expires_in => 3.months, :cache_path => Proc.new { |c| c.params }

  # GET /trip_reports
  # GET /trip_reports.xml
  def index
    @noindex = true #Don't let search engines index this page
    @record_class = @parent_class = TripReport
    @type = "Trip Report"
    @sort = params[:sort].blank? ? TripReport::DEFAULT_SORT : params[:sort]
    @lower = params[:lower].blank? ? nil : params[:lower]#Lower alphabetical starting point
    @upper = params[:upper].blank? ? nil : params[:upper]#Upper alphabetical starting point
    @records = TripReport.list(@sort, @lower, @upper).includes(:user).includes(:route).paginate :page=>params[:page]
    respond_to do |format|
      format.html { render :template => "all/index" }
      format.xml  { render :xml => @records }
    end
  end

  # GET /trip_reports/1
  # GET /trip_reports/1.xml
  def show
    begin
      @trip_report = TripReport.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @trip_report = TripReport.find(params[:id])
      flash.now[:notice] = "Rescued Not found exception"
    end

    logVisit @trip_report, true

    @route = @trip_report.route
    @pageTitle = @trip_report.title
    @metaDescription = @trip_report.abstract.blank? ? @trip_report.title : @trip_report.abstract
    @show_edit_link = can_edit?
    @can_edit_route = can_edit? && @route.user == current_user
    @google_map = @route.waypoints.count > 0
    @first_area_id = @route.areas.count == 0 ? nil : @route.areas.first.id
    
    unless read_fragment(:part => "google_map_#{@trip_report.id}") && @route.distance <= 0
      @centerLatitude = @route.averageLatitude 
      @centerLongitude = @route.averageLongitude
    end
    
    unless read_fragment(:part => "description_#{@trip_report.id}")
      @route = @trip_report.route
      @type = @route.class.to_s.tableize.humanize.singularize.titleize
      @start_time = @trip_report.start_time.nil? ? nil : @trip_report.start_time.strftime("%B %d %Y at %I:%M%P")
      @end_time = @trip_report.end_time.nil? ? nil : @trip_report.end_time.strftime("%B %d %Y at %I:%M%P")

      @dist = @route.distance
      @gain = @route.height_gain
      @loss = @route.height_loss
    end

    unless read_fragment(:part => "photos_#{@trip_report.id}")
      @photos = @trip_report.photos#.paginate :page=>params[:page], :per_page => 50
      @has_photos = @photos.length != 0
    end

    loadRecommendations
    loadComments

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @trip_report.to_xml(:include => {:route => {:include => :waypoints}}) }
    end
  end

  #Expires the cache fragments in the show method
  def expire
    if params[:id].blank?
      expire_index
    else
      @trip_report = TripReport.find(params[:id])
      expire_fragment(:action => "show", :part => "google_map_#{@trip_report.route.id}")
      expire_fragment(:action => "show", :part => "description_#{@trip_report.id}")
      expire_fragment(:action => "show", :part => "photos_#{@trip_report.id}")
      expire_fragment(:action => "photos", :part => "photos_#{@trip_report.id}")
      expire_fragment(:controller => "photos", :action => "slideshow", :trip_report_id => @trip_report.id, :type => 'Title')
      expire_fragment(:controller => "photos", :action => "show_full", :trip_report_id => @trip_report.id, :type => 'Title')
      respond_to do |format|
        format.html { redirect_to(@trip_report, :notice => 'Trip cache was cleared.') }
        format.xml  { head :ok }
      end
    end
  end

  #Expires the description fragment in the show method
  def expire_desc
    @trip_report = TripReport.find(params[:id])
    expire_fragment(:action => :show, :part => "description_#{@trip_report.id}")
    respond_to do |format|
      format.html { redirect_to(@trip_report, :notice => 'Trip cache was cleared.') }
      format.xml  { head :ok }
    end
  end

  #Returns partial html with photo thumbs. Requested by jquery after page load
  def photos
    @trip_report = TripReport.find(params[:id])
     
    unless read_fragment(:part => "photos_#{@trip_report.id}")
      @photos = @trip_report.photos#.paginate :page=>params[:page], :per_page => 50
      @has_photos = @photos.length != 0
    end

#if request.user_agent.downcase.include? "google"
#      UserMailer.notify_admins("Trip photos for #{@trip_report.title} has been requested by a google bot").deliver
#   end

    respond_to do |format|
      format.html { render :layout => false}
      format.xml  { render :xml => @user }
    end
  end


  # GET /trip_reports/new
  # GET /trip_reports/new.xml
  def new
    @trip_report = TripReport.new
    @trip_report.route_id = params[:route_id]
    @route = Route.find(params[:route_id])
    @start_time = ""
    @end_time = ""
    @startLatitude = @route.averageLatitude
    @startLongitude = @route.averageLongitude
    @multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
    @ref_title = @route.name
    @ref_latitude = @startLatitude
    @ref_longitude = @startLongitude

    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @trip_report.to_xml(:include => {:route => {:include => :waypoints}}) }
    end
  end

  # GET /trip_reports/1/edit
  def edit
    @trip_report = TripReport.find(params[:id])
    @start_time = @trip_report.start_time.nil? ? "" : @trip_report.start_time.strftime("%B %d %Y at %I:%M%P")
    @end_time = @trip_report.end_time.nil? ? "" : @trip_report.end_time.strftime("%B %d %Y at %I:%M%P")
    @startLatitude = @trip_report.route.averageLatitude
    @startLongitude = @trip_report.route.averageLongitude
    @multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
    @ref_title = @trip_report.route.name
    @ref_latitude = @startLatitude
    @ref_longitude = @startLongitude
    @id = params[:id]
    
    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @trip_report.to_xml(:include => {:route => {:include => :waypoints}}) }
    end
  end

  # GET /trip_report/multi_photos
  # GET /trip_report/multi_photos.xml
  def multi_photos
    begin
      if(!params[:trip_report_id].blank?)
        @multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
        @trip_report = TripReport.find(params[:trip_report_id])
	@ref_title = @trip_report.route.name
	@ref_latitude = @trip_report.route.averageLatitude
	@ref_longitude = @trip_report.route.averageLongitude
	@id = params[:id]
      else
        redirect_to trip_reports_path, :notice => "Cannot insert multiple photos without a trip report."
      end
    rescue ActiveRecord::RecordNotFound
      logger.error "Attempt to insert photos for an invalid trip report #{params[:trip_report_id]}. <br> This incident has been reported."
      redirect_to trip_reports_path, :notice => "Invalid trip report"
    else
      respond_to do |format|
        format.html { render :layout => 'nomenu' }
        format.xml  { render :xml => @photos }
      end
    end
  end

  # POST /trip_reports
  # POST /trip_reports.xml
  def create
    @trip_report = TripReport.new(trip_report_params)
    @trip_report.route_id = params[:trip_report][:route_id]
    @trip_report.user_id = current_user.id
 
    notice = "Trip report was successfully created." 

    respond_to do |format|
      if @trip_report.save
        params[:photo_ids] = "" if params[:photo_ids].nil? 
	Photo.find(params[:photo_ids].split(",")).each do |photo|
	  photo.update_attributes(:trip_report_id => @trip_report.id)
	end

        after_create()
	format.html { redirect_to(@trip_report, :notice => notice) }
        format.xml  { render :xml => @trip_report, :status => :created, :location => @trip_report }
      else
        @start_time = @trip_report.start_time.nil? ? "" : @trip_report.start_time.strftime("%B %d %Y at %I:%M%P")
        @end_time = @trip_report.end_time.nil? ? "" : @trip_report.end_time.strftime("%B %d %Y at %I:%M%P")
        @route = @trip_report.route
        @startLatitude = @route.averageLatitude
	@startLongitude = @route.averageLongitude
	@photos = []#Photo.search_nearby(@startLatitude, @startLongitude, 30, '', current_user.id)
        format.html { render :action => "new", :layout => 'nomenu' }
        format.xml  { render :xml => @trip_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /trip_reports/1
  # PUT /trip_reports/1.xml
  def update
    @trip_report = TripReport.find(params[:id])
    @trip_report.update_id = current_user.id

    respond_to do |format|
      if @trip_report.update_attributes(trip_report_params)
	if @trip_report.user != current_user && current_user.id != 1
          UserMailer.notify_admins("Photo: #{@trip_report.title} has been updated by #{current_user.display_name}").deliver
	end

        after_update()
        format.html { redirect_to(@trip_report, :notice => 'Trip report was successfully updated.') }
        format.xml  { head :ok }
      else
        @start_time = @trip_report.start_time.nil? ? "" : @trip_report.start_time.strftime("%B %d %Y at %I:%M%P")
        @end_time = @trip_report.end_time.nil? ? "" : @trip_report.end_time.strftime("%B %d %Y at %I:%M%P")
	@startLatitude = @trip_report.route.averageLatitude
	@startLongitude = @trip_report.route.averageLongitude
	@multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
	@photos = @trip_report.photos
	@ref_title = @trip_report.route.name
	@ref_latitude = @startLatitude
	@ref_longitude = @startLongitude
	@id = params[:id]
        format.html { render :action => "edit", :layout => 'nomenu' }
        format.xml  { render :xml => @trip_report.errors, :status => :unprocessable_entity }
      end
    end
  end


  # DELETE /trip_reports/1
  # DELETE /trip_reports/1.xml
  def destroy
#    @trip_report = TripReport.find(params[:id])
#    @trip_report.destroy

    respond_to do |format|
      format.html { redirect_to(trip_reports_url) }
      format.xml  { head :ok }
    end
  end

  protected

  def trip_report_params
    params.require(:trip_report).permit(:title, :start_time, :end_time, :travel_time, :abstract, :participants, :description)
  end

  def after_save
    if @trip_report.created_at >= TripReport.order('created_at DESC').limit(TripReport.per_page)[-1].created_at
      expire_fragment(:controller=>"trip_reports", :action=>"index")
      TripReport::SORT_OPTIONS.keys.each do |sort|
        expire_fragment(:controller=>"trip_reports", :action=>"index", :sort => sort)
      end
    end
      
    expire_fragment(:controller=>"users", :action=>"show", :id => @trip_report.user, :part => "trip_reports_#{@trip_report.user_id}")
    expire_fragment(:controller=>"users", :action=>"show", :id => @trip_report.user, :part => "trip_report_groups_#{@trip_report.user_id}")

    expire_fragment(:controller=>"routes", :action=>"show", :id => @trip_report.route, :part => "trip_reports_#{@trip_report.route.id}")

    @trip_report.route.places.each do |place|
      expire_fragment(:controller=>"places", :action=>"show", :id => place, :part => "trip_reports_#{place.id}")
    end

    unless @trip_report.route.place_id.nil?
      expire_fragment(:controller=>"places", :action=>"show", :id => @trip_report.route.place, :part => "trip_reports_#{@trip_report.route.place_id}")
    end
  end

  # If we create a new trip report, the public list of trip reports must be regenerated
  def after_create
    expire_fragment(:controller => 'main', :action => 'index', :part => 'trips_and_albums')
    expire_fragment(:controller => 'main', :action => 'index', :part => 'trips_and_albums_count')

    after_save()
  end

  # If we update an existing trip, the public list of updated trip reports must be regenerated
  def after_update
    #If trip_report is on the front page then expire the front page trip reports fragment
    if @trip_report.created_at >= TripReport.order('created_at DESC').limit(9)[-1].created_at
      expire_fragment(:controller => 'main', :action => 'index', :part => 'trips_and_albums')
    end
    expire_fragment(:controller => 'main', :action => 'updated', :part => 'trips_and_albums')
    expire_fragment(:controller=>"trip_reports", :action=>"show", :id => @trip_report, :part => "description_#{@trip_report.id}")
    
    after_save()
 end


end
