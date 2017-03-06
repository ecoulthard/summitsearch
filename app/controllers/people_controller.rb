class PeopleController < ApplicationController
  caches_action :index, :expires_in => 3.months, :cache_path => Proc.new { |c| c.params }
  #cache_sweeper :person_sweeper, :only => [:create, :update ]
  # GET /people
  # GET /people.json
  def index
    @record_class = @parent_class = Person
    @type = "Historical Mountain Person"
    @noindex = true #Don't let search engines index this page
    @sort = params[:sort].blank? ? Person::DEFAULT_SORT : params[:sort]
    @lower = params[:lower].blank? ? nil : params[:lower]#Lower alphabetical starting point
    @upper = params[:upper].blank? ? nil : params[:upper]#Upper alphabetical starting point
    @records = Person.list(@sort, @lower, @upper).paginate :page=>params[:page]

    respond_to do |format|
      format.html { render :template => "all/index" }
      format.json { render json: @people }
    end
  end

  # GET /people/1
  # GET /people/1.json
  def show
    @person = Person.find(params[:id])
    @pageTitle = @person.name
    @metaDescription = @person.description.blank? ? @person.name : @person.description

    unless read_fragment(:part => "ascents_#{@person.id}")
      @ascents = @person.ascents
      @first_ascent_count = @person.ascents.where("ascent_index = 1").count 
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @person }
    end
  end

  #Expires the cache fragments in the show method
  def expire
    if params[:id].blank?
      expire_index
    else
      @person = Person.find(params[:id])
      expire_fragment(:action => "show", :part => "ascents_#{@person.id}")
      expire_fragment(:action => "show", :part => "namings_#{@person.id}")
      respond_to do |format|
        format.html { redirect_to(@person, :notice => 'Person cache was cleared.') }
        format.xml  { head :ok }
      end
    end
  end

  # GET /people/new
  # GET /people/new.json
  def new
    @person = Person.new

    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @person }
      format.json { render json: @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
    
    respond_to do |format|
      format.html { render :layout => 'nomenu' }
      format.xml  { render :xml => @person }
      format.json { render json: @person }
    end
  end

  # POST /people
  # POST /people.json
  def create
    @person = Person.new(person_params)
    @person.insert_id = current_user.id

    respond_to do |format|
      if @person.save
	
	after_save()
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
        format.xml  { render :xml => @person, :status => :created, :location => @person }
        format.json { render json: @person, status: :created, location: @person }
      else
        format.html { render action: "new", :layout => 'nomenu' }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.json
  def update
    @person = Person.find(params[:id])
    @person.update_id = current_user.id

    respond_to do |format|
      if @person.update_attributes(person_params)

	after_save()
        format.html { redirect_to @person, notice: 'Person was successfully updated.' }
        format.xml  { head :ok }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  protected


  def person_params
    params.require(:person).permit(:guide, :birthdate, :deathdate, :description, :name, :photo_caption, :photo, :references
)
  end

  def after_save
    # If we update an existing person, the public list of updated persons must be regenerated
    if @person.created_at >= Person.order('created_at DESC').limit(Person.per_page)[-1].created_at
      expire_fragment(:controller=>"/people", :action=>"index")
      Person::SORT_OPTIONS.keys.each do |sort|
        expire_fragment(:controller=>"/people", :action=>"index", :sort => sort)
      end
    end
  end

end
