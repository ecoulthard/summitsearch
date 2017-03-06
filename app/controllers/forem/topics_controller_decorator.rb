Forem::TopicsController.class_eval do
  
  before_filter :multi_photos, :only => [:new]
  after_filter :attach_multi_photos, :only => [:create]
  
  def set_place_id
    @topic = Forem::Topic.find(params[:id])
    if Place.exists? params[:place_id]
      @topic.place_id = params[:place_id]
    end

    respond_to do |format|
      if @topic.save
        format.html { render :text => 'success' }
        format.xml { render :text => '{success:true}' }
      else
        format.xml  { render :xml => @topic.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  #Setup new action for multi photos upload
  def multi_photos
    @multiupload = !request.user_agent.include?("MSIE") && !request.user_agent.include?("Opera")
    @photos = []
    @ref_title = @ref_latitude = @ref_longitude = @id = nil
  end

  #After create attach topic id to each photo created.
  def attach_multi_photos
    return if @topic.id.nil? || params[:photo_ids].blank?
    Photo.find(params[:photo_ids].split(",")).each do |photo|
      photo.update_attributes(:topic_id => @topic.id)
    end
  end

end
