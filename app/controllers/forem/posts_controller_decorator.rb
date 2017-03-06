Forem::PostsController.class_eval do
  
  before_filter :multi_photos, :only => [:new,:edit]
  after_filter :update_counts, :only => [:create]

  private

  #Setup new or edit action for multi photos upload
  def multi_photos
    @multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
    topic = Forem::Topic.find(params[:topic_id])
    if topic.place.nil?
      @ref_title = @ref_latitude = @ref_longitude = @id = nil
    else
      @ref_title = topic.place.name
      @ref_latitude = topic.place.latitude
      @ref_longitude = topic.place.longitude
      @id = topic.id
    end
  end

  def update_counts
    article = nil
    article = @topic.trip_report unless @topic.trip_report.nil?
    article = @topic.album unless @topic.album.nil?
    article = @topic.photo unless @topic.photo.nil?
    unless article.nil?
      article.update_attributes(:last_comment_at => Time.now, :total_comments => @topic.posts.count)
    end
  end

end
