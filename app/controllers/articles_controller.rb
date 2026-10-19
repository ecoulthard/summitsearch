#This class contains actions common to Article classes such as trip reports, albums and photos
class ArticlesController < ApplicationController
  skip_before_action :authenticate_user!, :only => [:social_update, :photos], :raise => false
  skip_before_action :editor_required, :only => [:edit, :update, :new, :create, :thumbs_up, :two_thumbs_up, :social_update, :create_comment, :photos], :raise => false
  skip_before_action :admin_required, :only => [:thumbs_up, :two_thumbs_up, :social_update, :create_comment, :photos], :raise => false
#before_action :contributer_required, :except => [:thumbs_up, :two_thumbs_up, :social_update, :create_comment], :raise => false
  before_action :edit_permission_required, :except => [:index, :show, :new, :create, :expire, :thumbs_up, :two_thumbs_up, :social_update, :create_comment, :photos], :raise => false

  #Called when someone clicks facebook or google like/unlike.
  #Records the vote in the IpAddressTripReport table
  def social_update
    @article = article
    ip_record = IpAddress.find_or_create_by(address: request.remote_ip)
    visit = article.visits.find_or_initialize_by(ip_address: ip_record)

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
        # Send email notifying admin of the like or unlike.
        UserMailer.notify_admins_that_article_is_liked(article_type, @article.id, @article.title, liked, facebook, google, false).deliver_later
        UpdateArticleTotalLikesJob.perform_later(@article.class.to_s, @article.id, Time.current, liked)
        expire_fragment(controller: 'main', action: 'index', part: 'liked') if respond_to?(:expire_fragment)
        format.html { render plain: 'success' }
        format.xml { render plain: '{success:true}' }
      else
        format.xml { render xml: visit.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST :id/create_comment
  def create_comment
    @article = article
    ArticleComment.create!(article: @article, user: current_user, content: params[:text],
      reply_to_id: params[:reply_to_id], photo_ids: params[:forum_photo_ids])
    respond_to do |format|
      format.html { redirect_to @article, notice: "Comment added successfully" }
      format.xml { render xml: @article, status: :ok, location: @article }
    end
  rescue ArticleComment::NotAllowed, ForumPhotoAttachments::NotAllowed, ActiveRecord::RecordInvalid => error
    message = error.is_a?(ActiveRecord::RecordInvalid) ? error.record.errors.full_messages.to_sentence : error.message
    respond_to do |format|
      format.html { redirect_to @article, alert: message }
      format.xml { render plain: message, status: :unprocessable_entity }
    end
  end

  def thumbs_up
    change_rating(1)
  end
  
  protected

  def loadComments
    @forum_user = current_user || Thredded::NullUser.new
    @topic = article.topic
    @forum = @topic&.messageboard || article.forum
    @posts = Thredded::Post.none
    @can_comment = false
    return unless @forum && Thredded::MessageboardPolicy.new(@forum_user, @forum).read?

    if @topic
      return unless Thredded::TopicPolicy.new(@forum_user, @topic).read?

      @posts = Thredded::PostPolicy::Scope.new(@forum_user, @topic.posts).resolve
        .order_oldest_first.includes(:user).paginate(page: params[:page], per_page: 20)
      candidate = @topic.posts.build(messageboard: @forum)
      @can_comment = Thredded::PostPolicy.new(@forum_user, candidate).create?
      if params[:quote].present?
        reply = @posts.except(:limit, :offset).find_by(id: params[:reply_to_id])
        if reply
          text = reply.source == "forem" ? CGI.unescapeHTML(helpers.strip_tags(reply.content)) : reply.content
          @comment_text = Thredded::ContentFormatter.quote_content(text)
        end
      end
    else
      candidate = @forum.topics.build(user: current_user)
      @can_comment = user_signed_in? && Thredded::TopicPolicy.new(@forum_user, candidate).create?
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
      user_view = @article.views.find_by(user_id: current_user.id)
      if(user_view.rating.nil?)
        user_view.rating = rating
        if user_view.save
          # Send email notifying admin of the like or unlike.
          UserMailer.notify_admins_that_article_is_liked(article_type, @article.id, @article.title, rating > 0, false, false, true).deliver_later
          UpdateArticleTotalLikesJob.perform_later(@article.class.to_s, @article.id, Time.current)
          expire_fragment(controller: 'main', action: 'index', part: 'liked') if respond_to?(:expire_fragment)
          respond_to do |format|
            format.html { render plain: 'success' }
            format.xml { render plain: '{success:true}' }
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
    model = { "album" => Album, "photo" => Photo, "trip_report" => TripReport }[article_type]
    raise ActiveRecord::RecordNotFound unless model

    model.find(params[:id])
  end
  
  def article_type
    controller_name == "articles" ? params[:article_type].to_s : controller_name.singularize
  end

#  #If admin or owner or contributer you can see this trip report
#  def contributer_required
#    can_edit? || current_user.current_contributer? ? true : non_contributer_access_denied
#  end

end
