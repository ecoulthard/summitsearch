Forem::ForumsController.class_eval do

  def unanswered
    @noindex = true #Don't let search engines index this page
    initSort #Initialize variables shared by this and other actions.
    @days = 120

    @topics = Forem::Topic.order(@sort.to_sym => @direction.to_sym)
    @topics = @topics.joins(:posts).group(:topic_id).having("COUNT(*) = 1")
    @topics = @topics.where("last_post_at > ?", @days.days.ago) 
    @topics = @topics.limit(200)

    daysString = help.pluralize @days, "day"
    if @topics.length == 0
      @title = "No unanswered topics in the last #{daysString}" 
    else
      @title = "Unanswered Topics since #{daysString} ago"
    end

    respond_to do |format|
      format.html { render "search" }
    end
  end

  def active_topics
    @noindex = true #Don't let search engines index this page
    initSort #Initialize variables shared by this and other actions.
    @days = 7

    @topics = Forem::Topic.order(@sort.to_sym => @direction.to_sym)
    @topics = @topics.where("last_post_at > ?", @days.days.ago)
    @topics = @topics.limit(200)

    daysString = help.pluralize @days, "day"
    if @topics.length == 0
      @title = "No active topics in the last #{daysString}" 
    else
      @title = "Active Topics since #{daysString} ago"
    end

    respond_to do |format|
      format.html { render "search" }
    end
  end

  def list_topics
    @noindex = true #Don't let search engines index this page
    initSort
    @forum = Forem::Forum.find(params[:forum_id])
    if @sort == "num_replies"
      @topics = @forum.topics.joins(:posts).group(:topic_id).order("COUNT(*) #{"desc" if @direction == "desc"}")
    elsif  @sort == "author"  
      @topics = @forum.topics.joins(:forem_user).order("users.username #{"desc" if @direction == "desc"}")
    else    
      @topics = @forum.topics.order(@sort.to_sym => @direction.to_sym)
    end
    @topics = @topics.where("last_post_at > ?", params[:hours].to_i.hours.ago) unless params[:hours].blank?
    
    @topics = @topics.limit(200)
    @title = @forum.title
    @title = "No results to display for forum #{@forum.title}" if @topics.length == 0

    respond_to do |format|
      format.html { render "search" }
    end
  end

  def search
    @noindex = true #Don't let search engines index this page
    initSort
    
    @search_text = ""
    @search_text = Riddle::Query.escape(params[:search]) if params[:search].present?

    @topics = Forem::Topic.search @search_text,
      :page => params[:page],
      :per_page => 50,
      :order => "#{@sort} #{@direction}"
    
    #search = Sunspot.search Forem::Topic do
    #  fulltext params[:search] unless params[:search].blank?
    #  with(:last_post_at).greater_than params[:hours].to_i.hours.ago unless params[:hours].blank?
    #  with :num_replies, 1 unless params[:unanswered].blank?
    #  with :forum_id, params[:forum_id] unless params[:forum_id].blank?
    #  order_by params[:sort], params[:dir]
    #  paginate :page => params[:page], :per_page => 50
    #end
   
    @title = "Search Results for #{params[:search]}"
    @title = "No search results found" if @topics.length == 0

    respond_to do |format|
      format.html
    end
  end

  private

  #Initialize variables for sorting topics
  def initSort

    params[:dir] = "desc" if params[:dir].blank?
    @direction = params[:dir]
    params[:sort] = "last_post_at" if params[:sort].blank?
    @sort = params[:sort]
  end  

end
