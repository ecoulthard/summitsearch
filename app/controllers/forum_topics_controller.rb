class ForumTopicsController < ApplicationController
  layout "thredded/application"
  skip_before_action :authenticate_user!, :editor_required, :admin_required, raise: false

  def active
    @title = "Active Topics in the Last 7 Days"
    list(visible_topics.where("last_post_at > ?", 7.days.ago))
  end

  def unanswered
    @title = "Unanswered Topics in the Last 120 Days"
    # Count readable posts, so a hidden reply does not reveal its existence.
    posts = Thredded::PostPolicy::Scope.new(viewer, Thredded::Post.all).resolve
      .group(:postable_id).having("COUNT(*) = 1").select(:postable_id)
    list(visible_topics.where(id: posts).where("last_post_at > ?", 120.days.ago))
  end

  def search
    query = params[:q].presence || params[:search]
    if query.present?
      redirect_to thredded.messageboards_search_path(q: query.to_s)
    elsif params[:unanswered].present?
      redirect_to main_app.forum_unanswered_topics_path
    else
      redirect_to main_app.forum_active_topics_path
    end
  end

  private

  def viewer
    current_user || Thredded::NullUser.new
  end

  def visible_topics
    boards = Thredded::MessageboardPolicy::Scope.new(viewer, Thredded::Messageboard.all).resolve
    Thredded::TopicPolicy::Scope.new(viewer, Thredded::Topic.all).resolve.where(messageboard_id: boards.select(:id))
  end

  def list(scope)
    @topics = scope.order_recently_posted_first.includes(:messageboard)
      .forum_page(params[:page]).per(30)
    response.headers["X-Robots-Tag"] = "noindex"
    render :index
  end
end
