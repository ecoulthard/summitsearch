#This class contains actions common to Article classes such as trip reports, albums and photos
class ArticlesController < ApplicationController
  skip_before_filter :authenticate_user!, :only => [:social_update, :photos]
  skip_before_filter :editor_required, :only => [:edit, :update, :new, :create, :thumbs_up, :two_thumbs_up, :social_update, :create_comment, :photos]
  skip_before_filter :admin_required, :only => [:thumbs_up, :two_thumbs_up, :social_update, :create_comment, :photos]
#before_filter :contributer_required, :except => [:thumbs_up, :two_thumbs_up, :social_update, :create_comment]
  before_filter :edit_permission_required, :except => [:index, :show, :new, :create, :expire, :thumbs_up, :two_thumbs_up, :social_update, :create_comment, :photos]

  #Called when someone clicks facebook or google like/unlike.
  #Records the vote in the IpAddressTripReport table
  def social_update
    @article = article
    visit = article.visits.joins(:ip_address).where(:ip_addresses => {:address => request.remote_ip}).readonly(false).first

    #Was the article liked. If not then it was unliked.
    liked = params[:facebook_like] == "true" || params[:google_plus] == "true"

    #Is it a facebook like/unlike or google +1
    facebook = params[:facebook_like].present? 
    google = params[:google_plus].present?
 
    #update the like in the visit
    visit.facebook_like = liked if facebook
    visit.google_plus = liked if google

    respond_to do |format|
      if visit.save
        #Send email notifying admin of the like or unlike.
        NotifyAdminArticleLikedWorker.perform_async(article_type, @article.id, @article.title, liked, facebook, google, false)
	UpdateArticleTotalLikesWorker.perform_async(@article.class.to_s, @article.id, Time.now, liked)
        expire_fragment(:controller => 'main', :action => 'index', :part => 'liked')
	format.html { render :text => 'success' }
	format.xml { render :text => '{success:true}' }
      else
        format.xml  { render :xml => ipaddressArticle.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST :id/create_comment
  def create_comment
    article_type = controller_name.singularize
    @article = article

    topic = @article.topic
    success = false
    fail_notice = "" #What to say if it fails

    #If this is the first comment then we need to first create the topic.
    if topic.nil?
      forum = @article.forum
      if current_user.can_create_forem_topics? forum
        topic_title = @article.title.nil? ? @article.id.to_s : @article.title
        topic = forum.topics.build(:subject => help.link_to("#{article_type.titleize}: #{topic_title}", send("#{article_type}_path", :id => @article.id)), :posts_attributes => {"0" => {:text => params[:text]}})
        topic.user = @article.user
	topic[article_type.foreign_key] = @article.id

        success = topic.save
        #Subscribe the user to the comments.
        topic.subscribe_poster

	UpdateArticleTotalCommentsWorker.perform_async(@article.class.to_s, @article.id, Time.now)

        post = Forem::Post.find(topic.posts.first.id)
        post.user = current_user
        success = post.save
        if current_user != article.user
          SendArticleFirstCommentEmailWorker.perform_async(article_type, @article.class.to_s, @article.id)
        end
      else
        fail_notice = "You do not have permission to comment on this #{article_type.humanize}"
      end
    else #Add post to the topic
      if !current_user.can_reply_to_forem_topic? topic
        fail_notice = "You do not have permission to comment on this #{article_type.humanize}"
      elsif topic.locked?
        fail_notice = "Cannot add comment because commenting is locked for this #{article_type.humanize}"
      else
        post = topic.posts.build(:text => params[:text], :reply_to_id => params[:reply_to_id])
        post.user = current_user
        success = post.save
	UpdateArticleTotalCommentsWorker.perform_async(@article.class.to_s, @article.id, Time.now)
      end
    end

    respond_to do |format|
      if success
	#ExpireFragmentWorker.perform_async('main', 'index', 'commments')
        expire_fragment(:controller => 'main', :action => 'index', :part => 'comments')
	format.html { redirect_to(@article, :notice => "Comment added successfully") }
        format.xml  { render :xml => @article, :status => :updated, :location => @article }
      else
	format.html { redirect_to(@article, :notice => fail_notice) }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  def thumbs_up
    change_rating(1)
  end
  
  protected

  #A lot of this I got from Forem::TopicsController
  def loadComments
    @topic = article.topic
    @forum = article.forum
    if article.forum.present?
      if @topic.nil?
        @topic = article.forum.topics.build
      else
        @topic.register_view_by(forem_user)
      end 
      @posts = @topic.posts.page(params[:page]).per(20)
      @post = @topic.posts.build
      if params[:quote]
        @reply_to = @topic.posts.find(params[:reply_to_id])
        @post.text = view_context.forem_quote(@reply_to.text)
      end
    end
  end

  def loadRecommendations
    @total_visits = article.visits.sum(:count)
    @num_visitors = article.visits.count
    @num_thumbs_up = article.user_likes.count
    @num_facebook_likes = article.visits.where(facebook_like: true).count
    @num_google_plus = article.visits.where(google_plus: true).count
    @fans = article.fans
    #@total_views = article.views.sum(:count)
    #@num_viewers = article.views.count
    #@num_two_thumbs_up = article.views.where('rating = 2').count
  end

  def change_rating(rating)
    @article = article
    if(@article.user != current_user)
      user_view = @article.views.find_by_user_id(current_user.id)
      if(user_view.rating.nil?)
        user_view.rating = rating
        if user_view.save
          #Send email notifying admin of the like or unlike.
          NotifyAdminArticleLikedWorker.perform_async(article_type, @article.id, @article.title, rating > 0, false, false, true)
	  UpdateArticleTotalLikesWorker.perform_async(@article.class.to_s, @article.id, Time.now)
	  #ExpireFragmentWorker.perform_async('main', 'index', 'liked')
          expire_fragment(:controller => 'main', :action => 'index', :part => 'liked')
          respond_to do |format|
            format.html { render :text => 'success' }
            format.xml { render :text => '{success:true}' }
          end
	else
          change_rating_error_response 'Could not save rating'
	end
      else
        change_rating_error_response "You cannot rate a #{article_type.humanize} more than once"
      end
    else
      change_rating_error_response "You cannot rate your own #{article_type.humanize}"
    end
  end

  def change_rating_error_response(notice)
    respond_to do |format|
      format.html { redirect_to(@article, :notice => notice) }
      format.xml  { head :ok }
    end
  end

  def can_edit?
    @user = article.user
    user_signed_in? && (current_user.is_admin? || current_user == @user)
  end
  
  def edit_permission_required
    can_edit? ? true : permission_denied
  end

  #Load and return the article provided in the params.
  def article
    controller_name.singularize.camelize.constantize.find(params[:id])
  end
  
  def article_type
    controller_name.singularize
  end

#  #If admin or owner or contributer you can see this trip report
#  def contributer_required
#    can_edit? || current_user.current_contributer? ? true : non_contributer_access_denied
#  end

end
