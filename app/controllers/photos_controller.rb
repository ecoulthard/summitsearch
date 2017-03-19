class PhotosController < ArticlesController
  skip_before_filter :editor_required, :only => [:nearby_list, :slideshow, :show_full, :editable_list, :xhr_create, :thumb_edit, :thumb_update]
  skip_before_filter :admin_required, :only => [:nearby_list, :slideshow, :show_full, :editable_list, :xhr_create, :thumb_edit, :thumb_update]
#skip_before_filter :contributer_required, :only => [:index, :edit, :update, :new, :create, :xhr_create, :destroy, :thumb_edit, :thumb_update]
  skip_before_filter :edit_permission_required, :only => [:nearby_list, :slideshow, :show_full, :editable_list, :xhr_create, :thumb_edit, :thumb_update]
  before_filter :browsers_only, :only => [:slideshow, :show_full, :expire]

  caches_action :index, :expires_in => 3.months, :cache_path => Proc.new { |c| c.params }
  caches_action :slideshow, :cache_path => Proc.new { |c| c.params }
  caches_action :show_full, :cache_path => Proc.new { |c| c.params }

  # GET /photos
  # GET /photos.xml
  def index
    @noindex = true #Don't let search engines index this page
    @sort = params[:sort].blank? ? Photo::DEFAULT_SORT : params[:sort]
    @photos = Photo.list(@sort).includes(:user).includes(:place).paginate :page=>params[:page]
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @photos }
    end
  end

  # GET /photos
  # GET /photos.xml
  def nearby_list 
    #If no search text restrict search to within 30km otherwise search within 100km
    radius = params[:search].blank? ? 30 : 100
    search = params[:search].blank? ? "": params[:search]
    user_id = params[:only_my_photos].blank? || params[:only_my_photos] == "false" ? nil : current_user.id
    trip_report_id = params[:trip_report_id].blank? ? nil : params[:trip_report_id]
    topic_id = params[:topic_id].blank? ? nil : params[:topic_id]
    sort = params[:sort].blank? ? Photo::DEFAULT_SORT : params[:sort]
    @photos = Photo.search_nearby(params[:latitude].to_f, params[:longitude].to_f, radius, search, user_id, trip_report_id, topic_id, sort)
    respond_to do |format|
      format.html { render :partial => 'photos/nearby_list', :locals => {:photo => @photos} }
      format.xml  { head :ok }
    end
  end

  # GET /photos/1
  # GET /photos/1.xml
  def show
    setup_show
    respond_to do |format|
      format.html# show.html.erb
      format.xml  { render :xml => @photo }
    end
  end

  def slideshow 
    setup_slideshow
    respond_to do |format|
      format.html { render :layout => 'slideshow'} # show.html.erb
      format.xml  { render :xml => @photos }
    end
  end

  #Slideshow for full sized photos
  def show_full
    setup_slideshow
    respond_to do |format|
      format.html { render :layout => 'slideshow'} # show.html.erb
      format.xml  { render :xml => @photos }
    end
  end

  #Expires the cache fragments in the show method
  def expire
    if params[:id].blank?
      expire_index
    else
      @photo = Photo.find(params[:id])
      expire_fragment(:action => "show", :part => "google_map_#{@photo.id}")
      expire_fragment(:action => "show", :part => "description_#{@photo.id}")
      expire_fragment(:action => "show_full", :photo_id => @photo.id)
      expire_fragment(:action => "slideshow", :photo_id => @photo.id)
      respond_to do |format|
        format.html { redirect_to(@photo, :notice => 'Photo cache was cleared.') }
        format.xml  { head :ok }
      end
    end
  end


  # GET /photos/new
  # GET /photos/new.xml
  def new
    @photo = Photo.new
    if(!params[:route_id].blank?)
      @route = Route.find(params[:route_id])
      @photo.ref_latitude = @route.averageLatitude
      @photo.ref_longitude = @route.averageLongitude
      @photo.ref_title = @route.name
      @photo.ref_content = "Referrence Coordinate"
    elsif(!params[:trip_report_id].blank?)
      @trip_report = TripReport.find(params[:trip_report_id])
      @photo.trip_report_id = @trip_report.id
      if @trip_report.photos.count > 0
        ref_photo = @trip_report.photos.order('created_at DESC').first
        @photo.ref_latitude = ref_photo.ref_latitude
        @photo.ref_longitude = ref_photo.ref_longitude
        @photo.ref_title = ref_photo.ref_title
        @photo.ref_content = ref_photo.ref_content
        @photo.latitude = ref_photo.latitude
        @photo.longitude = ref_photo.longitude
        @photo.height = ref_photo.height
        @photo.vantage = ref_photo.vantage
        @photo.description = ref_photo.description
        flash.now[:notice] = "Many of the fields have been filled in from the previous photo you submitted to save you time if they were both taken at the same place. If this photo was taken in a different place then please change the fields to the correct values."
      else
        @photo.ref_latitude = @trip_report.route.averageLatitude
        @photo.ref_longitude = @trip_report.route.averageLongitude
        @photo.ref_title = @trip_report.route.name
        @photo.ref_content = "Referrence Coordinate"
        @photo.description = @trip_report.abstract
        flash.now[:notice] = "The description field has been auto filled for you with the abstract of the trip report. Feel free to change it if you like. "
      end
    elsif(!params[:place_id].blank?)
      @place = Place.find(params[:place_id])
      @photo.ref_latitude = @place.centerLatitude
      @photo.ref_longitude = @place.centerLongitude
      @photo.ref_title = @place.name
      @photo.ref_content = "Photo was inserted for " + @place.name
      @photo.title = @place.name
    elsif(!params[:photo_id].blank?)
      ref_photo = Photo.find(params[:photo_id])
      @photo.trip_report_id = ref_photo.trip_report_id
      @photo.ref_latitude = ref_photo.ref_latitude
      @photo.ref_longitude = ref_photo.ref_longitude
      @photo.ref_title = ref_photo.ref_title
      @photo.ref_content = ref_photo.ref_content
      @photo.latitude = ref_photo.latitude
      @photo.longitude = ref_photo.longitude
      @photo.height = ref_photo.height
      @photo.vantage = ref_photo.vantage
      @photo.description = ref_photo.description
      flash.now[:notice] = "Many of the fields have been filled in from the previous photo you submitted to save you time if they were both taken at the same place. If this photo was taken in a different place then please change the fields to the correct values."
    end
    @google_map = true
    respond_to do |format|
      format.html { render :layout => 'nomenu' }
            format.xml  { render :xml => @photo }
    end
  end
 
  # GET /photos/1/edit
  def edit
    @photo = Photo.find(params[:id])
    @time = @photo.time.nil? ? "" : @photo.time.strftime("%B %d %Y at %I:%M%P")
    @google_map = true
    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @photo }
    end
  end

  # POST /photos
  # POST /photos.xml
  def create
    @photo = Photo.new(photo_params)
    @photo.user = current_user
    notice = "Photo was successfully created." # You have been granted #{help.distance_of_time_in_words(Time.now, Time.now + User::NEW_PHOTO_CONTRIBUTION_AMOUNT)} of full site access in addition to any access time you already have."
#    if current_user.current_contributer? && current_user.contributer_until + User::NEW_PHOTO_CONTRIBUTION_AMOUNT > Time.now + User::MAX_ACCESS_TIME
#     notice += "<br>You have surpassed the maximum access time allowed. We are sorry, but we cannot grant any more than #{help.distance_of_time_in_words(Time.now, Time.now + User::MAX_ACCESS_TIME)} of access time."
#    end

    respond_to do |format|
      if @photo.save
        current_user.update_attributes(:last_photo_uploaded_at => Time.now)
        if(@photo.ref_title.include?("external"))
          notice = notice.gsub("created", "transferred")
          notice += "<br>" + help.link_to("Transfer another photo.", transfer_photos_index_path)
        else
          notice += "<br>" + help.link_to( "Submit another nearby photo.", new_photo_path(:photo_id => @photo.id))
        end
        if @photo.time.nil? && @photo.trip_report_id.nil?
          notice += "The photo file did not contain the photo time. You will need to enter this manually if you want the photo to link to a trip report."
        end

        after_create()
        format.html { redirect_to(@photo, :notice => notice) }
        format.json
        format.xml  { render :xml => @photo, :status => :created, :location => @photo }
      else
        @google_map = true
        @time = @photo.time.nil? ? "" : @photo.time.strftime("%B %d %Y at %I:%M%P")
        #flash.now[:notice] = "params: #{params.keys.to_s}"
	      format.html { render :action => "new", :layout => 'nomenu' }
        #format.json
        format.xml  { render :xml => @photo.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /photos/1
  # PUT /photos/1.xml
  def update
    @photo = Photo.find(params[:id])
    @photo.update_id = current_user.id

    respond_to do |format|
      if @photo.update_attributes(photo_params)
	if @photo.user != current_user && current_user.id != 1
          UserMailer.notify_admins("Photo: id:#{@photo.id}, #{@photo.title} has been updated by #{current_user.display_name}").deliver
	end
        after_update()
        format.html { redirect_to(@photo, :notice => 'Photo was successfully updated.') }
        format.xml  { head :ok }
      else
        @google_map = true
	@time = @photo.time.nil? ? "" : @photo.time.strftime("%B %d %Y at %I:%M%P")
        format.html { render :action => "edit", :layout => 'nomenu' }
        format.xml  { render :xml => @photo.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /photos/1
  # DELETE /photos/1.xml
  def destroy
#@photo = Photo.find(params[:id])
#@photo.destroy

    respond_to do |format|
      format.html { redirect_to(photos_url) }
      format.xml  { head :ok }
    end
  end

  #Load editable photos partial for multi edit page.
  def editable_list
    if !params[:trip_report_id].blank?
      @photos = TripReport.find(params[:trip_report_id]).photos
    elsif !params[:album_id].blank?
      @photos = Album.find(params[:album_id]).photos
    elsif !params[:topic_id].blank?
      @photos = Forem::Topic.find(params[:topic_id]).uploaded_photos.where('user_id = ?', current_user.id)
    end
    respond_to do |format|
      format.html { render :partial => 'photos/editable_list' }
      format.xml  { head :ok }
    end
  end

  # POST
  # This create function is called by a multi upload page. So far includes trip reports, albums and forum topics.
  # The photo is sent differently in firefox and chrome, so we need to load it into Paperclip differently
  # We also need to send the response back in text as success.
  def xhr_create
    @photo = Photo.new(photo_params)
    puts "Params: #{params.to_yaml}"
    puts "********************** Here **************************"
    if !params['qqfile'].nil?
      #IE 7,8,9 passes the file the usual way.
      if request.user_agent =~ /MSIE 7.0|MSIE 8.0|MSIE 9.0/i
        @photo.photo = params['qqfile']
      #Photo is stored in request.body.read. Need to save it in a temporary file before passing it to paperclip
      else #Handle Chrome/Firefox/IE >= 10 photos
        @filename = sanitize_filename(params['qqfile'])
	puts @filename
        Dir.mkdir("/tmp/#{current_user.id}") unless FileTest.exists?("/tmp/#{current_user.id}")
        newfile = File.open("/tmp/#{current_user.id}/#{@filename}", "wb+")
        data =  request.body.read
        newfile.write(data)
        newfile.rewind
        @photo.photo = newfile
        
        geo = Paperclip::Geometry.from_file(newfile.path)
        @photo.photo_width = geo.width unless geo.width.nil?
        @photo.photo_height = geo.height unless geo.height.nil?

        exif_img = EXIFR::JPEG.new(newfile.path)
        #Grab photo time in order to compare against other photos to prevent duplicates.
        @photo.time = exif_img.date_time_original.strftime("%B %d %Y at %I:%M%P") unless exif_img.date_time_original.nil?
	unless exif_img.gps_latitude.nil?
          lat = exif_img.gps_latitude
          sign = exif_img.gps_latitude_ref == "N" ? 1 : -1
          @photo.latitude = sign*lat[0].to_f + sign*lat[1].to_f/60 + sign*lat[2].to_f/3600
	end
        unless exif_img.gps_longitude.nil?
          lon = exif_img.gps_longitude
          sign = exif_img.gps_longitude_ref == "E" ? 1 : -1
          @photo.longitude = sign*lon[0].to_f + sign*lon[1].to_f/60 + sign*lon[2].to_f/3600
        end
        @photo.height = exif_img.gps_altitude unless exif_img.gps_altitude.nil?
      end
    end
    @photo.user = current_user
    @photo.title=nil
    respond_to do |format|
      if @photo.save
        current_user.update_attributes(:last_photo_uploaded_at => Time.now)
        after_create()
        if !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
          #The photo was successfully created. We can now delete the temporary file.
	  newfile.close
	  tmpFilename = "public/system/users/photos/#{current_user.id}/tmp/#{@filename}"
	  File.delete(tmpFilename) if File.exists?(tmpFilename)
	end
        
	if @photo.album_id.present?
          expire_fragment(:controller => "albums", :action => "show", :id => @photo.album.to_param, :part => "photos_#{@photo.album_id}")
          expire_fragment(:controller => "albums", :action => "photos", :id => @photo.album.to_param, :part => "photos_#{@photo.album_id}")
	end
        if @photo.trip_report_id.present?
          expire_fragment(:controller => "trip_reports", :action => "show", :id => @photo.trip_report.to_param, :part => "photos_#{@photo.trip_report_id}")
          expire_fragment(:controller => "trip_reports", :action => "photos", :id => @photo.trip_report.to_param, :part => "photos_#{@photo.trip_report_id}")
	end

        format.json
	format.html { render :text => "{success:true, 'id':#{@photo.id}}" }
	format.xml { render :text => "{success:true, 'id':#{@photo.id}}" }
      else
        format.xml  { render :text => "{success:false, 'errors':#{@photo.errors}}" }
      end
    end
  end

  #Called from multi_edit
  def thumb_update
    @photo = Photo.find(params[:id])
    @photo.title = params[:title]
    @photo.time = params[:time]
    @photo.caption = params[:caption]
    @photo.update_id = current_user.id
    respond_to do |format|
      if @photo.save
	format.html { render :text => 'success' }
	format.xml { render :text => '{success:true}' }
      else
        format.xml  { render :xml => @photo.errors, :status => :unprocessable_entity }
      end
    end
  end

  protected

  def setup_slideshow
    if(!params[:photo_id].blank?)
      @photo = Photo.find(params[:photo_id])
      @photos = @photo.trip_report_id.nil? ? [@photo] : @photo.trip_report.photos
    elsif(!params[:trip_report_id].blank?)
      @photos = TripReport.find(params[:trip_report_id]).photos
    elsif(!params[:album_id].blank?)
      @photos = Album.find(params[:album_id]).photos
    elsif(!params[:place_id].blank? && params[:type] == "Title")
      @photos = Place.find(params[:place_id]).photos
    elsif(!params[:place_id].blank? && params[:type] == "Mentioned")
      @photos = Place.find(params[:place_id]).photo_appearances
    elsif(!params[:place_id].blank? && params[:type] == "InArea")
      @photos = Place.find(params[:place_id]).photos_in_area.limit(200)
    elsif(!params[:route_id].blank? && params[:type] == "Title")
      @photos = Route.find(params[:route_id]).photos
    elsif(!params[:route_id].blank? && params[:type] == "Mentioned")
      @photos = Route.find(params[:route_id]).photo_appearances
    elsif(!params[:user_id].blank?)
      @photos = User.find(params[:user_id]).recently_submitted_photos.limit(300)
    else
      @photos = Photo.order('created_at DESC').limit(200)
    end
  end

  #Called by show
  def setup_show
    @photo = Photo.find(params[:id])
    logVisit @photo, true

    @pageTitle = (@photo.title.nil? ? "" : @photo.title) + " Photo"
    @metaDescription = @photo.caption.blank? ? @photo.title : @photo.caption
    if !@photo.latitude.nil? && !@photo.longitude.nil?
      @google_map = true
    end
    @centerLatitude = @photo.lat_for_map
    @centerLongitude = @photo.lon_for_map
    @first_area_id = @photo.areas.count == 0 ? nil : @photo.areas.first.id

    unless read_fragment(:part => "google_map_#{@photo.id}")
      @places = @photo.places
    end

    #Set which photo to render and which layout
    if(!params[:full_size].blank? && params[:full_size].to_s == "true")
	@full_size = true
    else
    	@full_size = false
    end
    @show_edit_link = can_edit?

    unless read_fragment(:part => "description_#{@photo.id}")
      @time = @photo.time.nil? ? nil : @photo.time.strftime("%B %d %Y at %I:%M%P")
      @caption = @photo.caption
      if @caption
        #Add links for each place mentioned in the caption
        @photo.places.each do |place|
          place.full_names.each do |name|
            if @caption.downcase.include? name.downcase
	      name_string = @caption[@caption.downcase.index(name.downcase), name.length]
              @caption = @caption.gsub(name_string, help.link_to(name_string, url_for(place)))
	      break
	    end
          end
        end
      end

      if @photo.title_places.length != 0
        #Photo.find(27).title_places.map {|place| {:place => place.name, :dist => 1, :height => 2} }
        if @photo.latitude? && @photo.longitude?
          @distance = @photo.place.dist(@photo.latitude, @photo.longitude).round(2)
          @direction = @photo.place.direction(@photo.latitude, @photo.longitude)
        end
      end
    end
    
    loadComments
    loadRecommendations
  end

  
  def photo_params
    params.require(:photo).permit(:title, :photo, :time, :description, :height, :latitude, :longitude, :ref_latitude, :ref_longitude, :ref_title, :ref_content, :album_id, :trip_report_id, :topic_id, :caption, :vantage)
  end

  def sanitize_filename(filename)
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    # Finally, join the parts with a period and return the result
    return fn.join '.'
  end

  def after_save
    if @photo.created_at >= Photo.order('created_at DESC').limit(Photo.per_page)[-1].created_at
      expire_fragment(:controller=>"photos", :action=>"index")
      Photo::SORT_OPTIONS.keys.each do |sort|
        expire_fragment(:controller=>"photos", :action=>"index", :sort => sort)
      end
    end
      
    if @photo.created_at >= @photo.user.photos.limit(200)[-1].created_at
      expire_fragment(:controller=>"users", :action=>"show", :id => @photo.user, :part => "photos_#{@photo.user_id}")
    end

    @photo.places_mentioned.each do |place|
      expire_fragment(:controller=>"places", :action=>"show", :id => place, :part => "photos_#{place.id}")
    end
    
    @photo.routes_mentioned.each do |route|
      expire_fragment(:controller=>"routes", :action=>"show", :id => route, :part => "photos_#{route.id}")
    end

    unless @photo.album_id.nil?
      expire_fragment(:controller=>"albums", :action=>"show", :id => @photo.album, :part => "photos_#{@photo.album_id}")
    end

    unless @photo.place_id.nil?
      expire_fragment(:controller=>"places", :action=>"show", :id => @photo.place, :part => "description_#{@photo.place_id}")
      expire_fragment(:controller=>"places", :action=>"show", :id => @photo.place, :part => "photos_#{@photo.place_id}")
      expire_fragment(:controller=>"places", :action=>"infowindow", :id => @photo.place, :part => "infowindow_0")
      @photo.place.areas.each do |area|
        expire_fragment(:controller=>"places", :action=>"show", :id => area, :part => "google_map_#{area.id}")
      end
    end
    
    unless @photo.route_id.nil?
      expire_fragment(:controller=>"routes", :action=>"show", :id => @photo.route, :part => "photos_#{@photo.route_id}")
    end

    unless @photo.trip_report_id.nil?
      expire_fragment(:controller=>"trip_reports", :action=>"show", :id => @photo.trip_report, :part => "photos_#{@photo.trip_report_id}")
      expire_fragment(:controller => "photos", :action => "slideshow", :trip_report_id => @photo.trip_report, :type => 'Title')
      expire_fragment(:controller => "photos", :action => "show_full", :trip_report_id => @photo.trip_report, :type => 'Title')
    end
  end

  # If we create a new photo, the public list of photos must be regenerated
  def after_create
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    expire_fragment(:controller => 'main', :action => 'index', :part => 'photos')
    expire_fragment(:controller => 'users', :action => 'photos', :id => @photo.user.id, :part => "photos_new_#{@photo.user_id}")
    expire_fragment(:controller => 'main', :action => 'index', :part => 'photo_count')
    if (!@photo.trip_report.nil? && @photo.trip_report.photos.first == @photo) || (!@photo.album.nil? && @photo.album.photos.first == @photo)
      expire_fragment(:controller => 'main', :action => 'index', :part => 'trips_and_albums')
    end

    after_save()
  end

  # If we update an existing photo, the public list of updated photos must be regenerated
  def after_update
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    #If photo is on the front page then expire the front page user photos fragment
    if @photo.user.photos.count > 0 && @photo.created_at >= 1.day.ago
      expire_fragment(:controller => 'main', :action => 'index', :part => 'photos')
      expire_fragment(:controller => 'users', :action => 'photos', :id => @photo.user.id, :part => "photos_new_#{@photo.user_id}")
    end
    expire_fragment(:controller => 'main', :action => 'updated', :part => 'photos')
    expire_fragment(:controller => 'users', :action => 'photos', :id => @photo.user, :part => "photos_popular_#{@photo.user_id}")
    
    expire_fragment(:controller=>"photos", :action=>"show", :id => @photo, :part => "description_#{@photo.id}")
    expire_fragment(:controller=>"photos", :action=>"show", :id => @photo, :part => "google_map_#{@photo.id}")

    after_save()
  end


end
