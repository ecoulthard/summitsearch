class AlbumsController < ArticlesController
  skip_before_filter :editor_required, :only => [:multi_photos]
  skip_before_filter :admin_required, :only => [:multi_photos]
#skip_before_filter :contributer_required, :only => [:index, :edit, :update, :new, :create, :destroy]
  skip_before_filter :edit_permission_required, :only => [:destroy]

  caches_action :index, :expires_in => 3.months, :cache_path => Proc.new { |c| c.params }
#  cache_sweeper :album_sweeper, :only => [:new, :create, :update, :social_update, :create_comment, :thumbs_up ]

  # GET /albums
  # GET /albums.xml
  def index
    @noindex = true #Don't let search engines index this page
    @record_class = @parent_class = Album
    @type = "Album"
    @sort = params[:sort].blank? ? Album::DEFAULT_SORT : params[:sort]
    @lower = params[:lower].blank? ? nil : params[:lower]#Lower alphabetical starting point
    @upper = params[:upper].blank? ? nil : params[:upper]#Upper alphabetical starting point
    @records = Album.list(@sort, @lower, @upper).includes(:user).paginate :page=>params[:page]
    respond_to do |format|
      format.html { render :template => "all/index" }
      format.xml  { render :xml => @records }
    end
  end

  # GET /albums/1
  # GET /albums/1.xml
  def show
    @album = Album.find(params[:id])

    logVisit @album, true

    @pageTitle = @album.title
    @metaDescription = @album.description.blank? ? @album.title : @album.description
    @first_area_id = @album.areas.count == 0 ? nil : @album.areas.first.id
    @show_edit_link = can_edit?
    @canInsertPhoto = user_signed_in? && current_user == @album.user
    
    unless read_fragment(:part => "description_#{@album.id}")
      @description = @album.description
      if @description
        #Add links for each place mentioned in the caption
        @album.places.each do |place|
          place.articleFullyQualifiedMatchNames.each do |name|
            if @description.downcase.include? name.downcase
	      name_string = @description[@description.downcase.index(name.downcase), name.length]
              @description = @description.gsub(name_string, help.link_to(name_string, url_for(place)))
	      break
	    end
          end
        end
      end
      @time = @album.time.nil? ? nil : @album.time.strftime("%B %d %Y")
    end

    unless read_fragment(:part => "photos_#{@album.id}")
      @photos = @album.photos
      @has_photos = @photos.length != 0
    end

    loadRecommendations
    loadComments

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @album }
    end
  end

  #Expires the cache fragments in the show method
  def expire
    if params[:id].blank?
      expire_index
    else
      @album = Album.find(params[:id])
      expire_fragment(:action => "show", :part => "description_#{@album.id}")
      expire_fragment(:action => "show", :part => "photos_#{@album.id}")
      expire_fragment(:action => "photos", :part => "photos_#{@album.id}")
      respond_to do |format|
        format.html { redirect_to(@album, :notice => 'Album cache was cleared.') }
        format.xml  { head :ok }
      end
    end
  end

  #Returns partial html with photo thumbs. Requested by jquery after page load
  def photos
    @album = Album.find(params[:id])
     
    unless read_fragment(:part => "photos_#{@album.id}")
      @photos = @album.photos
      @has_photos = @photos.length != 0
    end

#if request.user_agent.downcase.include? "google"
#      UserMailer.notify_admins("Album photos for #{@album.title} has been requested by a google bot").deliver
#    end

    respond_to do |format|
      format.html { render :layout => false}
      format.xml  { render :xml => @user }
    end
  end

  # GET /albums/new
  # GET /albums/new.xml
  def new
    @album = Album.new
    @album.user_id = current_user.id
    if(!params[:place_id].blank?)
      @place = Place.find(params[:place_id])
      @album.ref_latitude = @place.latitude
      @album.ref_longitude = @place.longitude
      @album.ref_title = @place.name
      @album.ref_content = "Album was inserted for " + @place.name
    elsif(!params[:route_id].blank?)
      @route = Route.find(params[:route_id])
      @album.ref_latitude = @route.averageLatitude
      @album.ref_longitude = @route.averageLongitude
      @album.ref_title = @route.name
      @album.ref_content = "Album was inserted for " + @route.name
    end
    
    @album.deleted = true #Considered deleted until content or photos are added
    
    if @album.save
      #Delete this users unused empty albums
      albums_to_delete = Album.where('user_id = :user_id and deleted = true and updated_at < :time', {:user_id => current_user.id, :time => (Time.now-1.day)})
      albums_to_delete.each do |album|
        album.destroy
      end

      respond_to do |format|
        format.html { redirect_to(edit_album_path(@album)) }
        format.xml  { render :xml => @album }
      end

    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /albums/1/edit
  def edit
    @album = Album.find(params[:id])
    @multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
    @ref_title = "#{@album.user.display_name}'s Album_#{@album.id}"
    @ref_latitude = @album.ref_latitude
    @ref_longitude = @album.ref_longitude
    @id = params[:id]
    @album.deleted = false

    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @album }
    end
  end

  # POST /albums
  # POST /albums.xml
  def create
    @album = Album.new(album_params)
    @album.user_id = current_user.id

    respond_to do |format|
      if @album.save
        after_create()
        format.html { redirect_to(@album) }
        format.xml  { render :xml => @album, :status => :created, :location => @album }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /albums/1
  # PUT /albums/1.xml
  def update
    @album = Album.find(params[:id])
    @album.update_id = current_user.id
    @album.deleted = false

    respond_to do |format|
      if @album.update_attributes(album_params)
	if @album.user != current_user && current_user.id != 1
          UserMailer.notify_admins("Album: #{@album.title} has been updated by #{current_user.display_name}").deliver
	end

        after_update()
	format.html { render :text => 'success' }
	format.xml { render :text => '{success:true}' }
      else
        format.xml  { render :xml => @album.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /albums/1
  # DELETE /albums/1.xml
  def destroy
#    @album = Album.find(params[:id])
#    @album.destroy

    respond_to do |format|
      format.html { redirect_to(albums_url) }
      format.xml  { head :ok }
    end
  end

private

  def album_params
    params.require(:album).permit(:title, :description, :time, :ref_latitude, :ref_longitude, :ref_title, :ref_content)
  end

  #Expire the album parts of other records show pages
  def after_save
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    if @album.created_at >= Album.order('created_at DESC').limit(Album.per_page)[-1].created_at
      expire_fragment(:controller=>"albums", :action=>"index")
      Album::SORT_OPTIONS.keys.each do |sort|
        expire_fragment(:controller=>"albums", :action=>"index", :sort => sort)
      end
    end
    
    expire_fragment(:controller=>"users", :action=>"show", :id => @album.user, :part => "albums_#{@album.user_id}")

    unless @album.place_id.nil?
      expire_fragment(:controller=>"places", :action=>"show", :id => @album.place, :part => "albums_#{@album.place_id}")
    end

    unless @album.route_id.nil?
      expire_fragment(:controller=>"routes", :action=>"show", :id => @album.route, :part => "albums_#{@album.route_id}")
    end
    
    @album.areas.each do |area|
      expire_fragment(:controller=>"places", :action=>"show", :id => area, :part => "albums_#{area.id}")
    end

    @album.places_mentioned.each do |place|
      expire_fragment(:controller=>"places", :action=>"show", :id => place, :part => "albums_#{place.id}")
    end

    @album.routes_mentioned.each do |route|
      expire_fragment(:controller=>"routes", :action=>"show", :id => route, :part => "albums_#{route.id}")
    end
    
  end

  # If we create a new album, the public list of albums must be regenerated
  def after_create
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    expire_fragment(:controller => 'main', :action => 'index', :part => 'trips_and_albums')
    expire_fragment(:controller => 'main', :action => 'index', :part => 'trips_and_albums_count')

    after_save()
  end

  # If we update an existing album, the public list of updated albums must be regenerated
  def after_update
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    #If album is on the front page then expire the front page albums fragment
    if @album.created_at >= Album.order('created_at DESC').limit(9)[-1].created_at
      expire_fragment(:controller => 'main', :action => 'index', :part => 'trips_and_albums')
    end
    expire_fragment(:controller => 'main', :action => 'updated', :part => 'trips_and_albums')
    expire_fragment(:controller=>"albums", :action=>"show", :id => @album, :part => "description_#{@album.id}")
    
    after_save()
  end

end
