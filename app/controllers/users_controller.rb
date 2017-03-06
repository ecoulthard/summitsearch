class UsersController < ApplicationController
  skip_before_filter :authenticate_user!, :only => [:photos]
  skip_before_filter :admin_required, :only => [:photos, :make_editor]
  skip_before_filter :editor_required, :only => [:photos]
  before_filter :edit_permission_required, :except => [:index, :admin_index, :show, :photos, :make_editor, :expire]
  
  caches_action :index, :expires_in => 3.months, :cache_path => Proc.new { |c| c.params }

  # GET /users
  # GET /users.xml
  def index
    @record_class = @parent_class = User
    @type = "Member"
    @noindex = true #Don't let search engines index this page
    @sort = params[:sort].blank? ? User::DEFAULT_SORT : params[:sort]
    @lower = params[:lower].blank? ? nil : params[:lower]#Lower alphabetical starting point
    @upper = params[:upper].blank? ? nil : params[:upper]#Upper alphabetical starting point
    @records = User.list(@sort, @lower, @upper).paginate :page=>params[:page]

    respond_to do |format|
      format.html { render :template => "all/index" }
      format.xml  { render :xml => @records }
    end
  end

  # GET /users
  # GET /users.xml
  #Displays information to admin. If admin display latest 5 users signed in. Displays browser usage
  #and OS usage statistics.
  def admin_index
    @sort = params[:sort].blank? ? User::DEFAULT_SORT : params[:sort]
    @lower = params[:lower].blank? ? nil : params[:lower]#Lower alphabetical starting point
    @upper = params[:upper].blank? ? nil : params[:upper]#Upper alphabetical starting point
    @users = User.list(@sort, @lower, @upper).paginate :page=>params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    if @user.slug != params[:id]
      redirect_to(@user, :status => :moved_permanently)
      return
    end

    @pageTitle = @user.display_name
    @metaDescription = @user.description.blank? ? @user.display_name : @user.description
    @homepage = @user.home_page
    @homepage = "http://" + @homepage unless @homepage.nil? || @homepage.downcase.starts_with?("http://")
    unless read_fragment(:part => "photos_#{@user.id}")
      @photos = @user.photos_by_time.limit(Photo.per_page)
      @has_photos = @photos.length != 0
      @appears_in_other_photos = false
    end
    unless read_fragment(:part => "trip_reports_#{@user.id}")
      @trip_reports_by_sub_region = @user.trip_reports_by_sub_region
      @trip_reports_by_year = @user.trip_reports_by_year
      @trip_year_groups = @trip_reports_by_year.keys.in_groups(1)
      @trip_year_groups = @trip_reports_by_year.keys.in_groups(2) if @trip_reports_by_year.length >= 6 
      @trip_year_groups = @trip_reports_by_year.keys.in_groups(3) if @trip_reports_by_year.length >= 11 
      @has_trip_reports = @user.trip_reports.length != 0
    end
    unless read_fragment(:part => "albums_#{@user.id}")
      @albums = @user.albums.where('deleted=false').includes(:user)
      @has_albums = @albums.length != 0
      @album_groups = @albums.in_groups_of(1)
      @appears_in_other_albums = false
    end
    @show_edit_link = can_edit?

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  #Expires the cache fragments in the show method
  def expire
    if params[:id].blank?
      expire_index
    else
      @user = User.find(params[:id])
      expire_fragment(:action => "show", :part => "photos_#{@user.id}")
      expire_fragment(:action => "show", :part => "trip_report_groups_#{@user.id}")
      expire_fragment(:action => "show", :part => "trip_reports_#{@user.id}")
      expire_fragment(:action => "show", :part => "albums_#{@user.id}")
      expire_fragment(:action => "photos", :id => @user.id, :part => "photos_new_#{@user.id}")
      expire_fragment(:action => "photos", :id => @user.id,  :part => "photos_updated_#{@user.id}")
      expire_fragment(:action => "photos", :id => @user.id,  :part => "photos_popular_#{@user.id}")
      expire_fragment(:action => "photos", :id => @user.id,  :part => "photos_#{@user.id}")
      respond_to do |format|
        format.html { redirect_to(@user, :notice => 'User cache was cleared.') }
        format.xml  { head :ok }
      end
    end
  end

  # GET /users/1/statistics
  # GET /users/1/statistics.xml
  def statistics
    @user = User.find(params[:id])
    @pageTitle = @user.display_name + " Site History"
    @metaDescription = @user.description.blank? ? @user.display_name : @user.description
    @trip_report_visit_groups = @user.trip_report_visits.order("updated_at DESC").limit(30).in_groups_of(3)
    @place_visit_groups = @user.place_visits.order("updated_at DESC").limit(30).in_groups_of(3)
    @photo_visits = @user.photo_visits.order("updated_at DESC").limit(30)
    @route_visit_groups = @user.route_visits.order("updated_at DESC").limit(30).in_groups_of(3)
    @album_visit_groups = @user.album_visits.order("updated_at DESC").limit(30).in_groups_of(3)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @user }
    end
  end

  #Returns partial html with user photo thumbs. Used by jquery.
  def photos
    @user = User.find(params[:id])
    @type = params[:type]
    unless read_fragment(:part => "photos_#{@type}_#{@user.id}")
      if(@type == "new" && @user.last_photo_uploaded_at < 5.minutes.ago)
        @photos = @user.recently_submitted_photos.where("created_at > ?", @user.recently_submitted_photos.first.created_at - 1.day).reverse
      elsif(@type == "updated")
        @photos = @user.updated_photos.where("updated_at > ?", 1.day.ago).reverse
      elsif(@type == "popular")
        @photos = @user.popular_photos.limit(50)
      elsif(@type != "new")
        @photos = @user.photos.limit(50)
      end
    end

#if request.user_agent.downcase.include? "google"
#      UserMailer.notify_admins("User photos for #{@user.display_name} has been requested by a google bot").deliver
#    end

    respond_to do |format|
      format.html { render :layout => false}
      format.xml  { render :xml => @user }
    end
  end

  def make_editor
    change_user_role("Editor")
  end

  def make_admin
    change_user_role("Admin")
  end

  def demote
    change_user_role("Author")
  end

  protected

  def change_user_role(role_name)
    @user = User.find(params[:id])
    
    if(@user != current_user)
      UserMailer.notify_admins("User: #{@user.display_name}'s role has changed from #{@user.role} to #{role_name}").deliver
      @user.role_index = User::ROLES.index(role_name)
      if role_name != "Author"
        @user.notifications += "<br>" unless @user.notifications.nil?
        @user.notifications = "" if @user.notifications.nil?
        @user.notifications += "Congratulations you have been promoted to #{role_name} by #{current_user.display_name}."
      end
      @user.save
      respond_to do |format|
        format.html { redirect_to(users_url) }
	format.js { @user } 
        format.xml  { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(users_url, :notice => 'You cannot change your own role.') }
        format.xml  { head :ok }
      end
    end

  end

  def can_edit?
    @user = User.find(params[:id])
    user_signed_in? && (current_user.is_admin? || current_user.id == @user.id)
  end
  
  def edit_permission_required
    can_edit? ? true : permission_denied
  end
end
