# Read-only compatibility URLs. Destination controllers enforce current policies.
class LegacyForumRedirectsController < ApplicationController
  skip_before_action :authenticate_user!, :editor_required, :admin_required, raise: false

  def index
    redirect_to thredded.root_path, status: :moved_permanently
  end

  def list
    destination = params[:forum_id].present? ? thredded.messageboard_topics_path(board) : thredded.root_path
    redirect_to destination
  end

  def forum
    redirect_to thredded.messageboard_topics_path(board), status: :moved_permanently
  end

  def topic
    redirect_to thredded.messageboard_topic_path(board, discussion), status: :moved_permanently
  end

  def post
    raise ActiveRecord::RecordNotFound unless params[:post_id].to_s.match?(/\A[1-9]\d*\z/)

    record = discussion.posts.find_by!(forem_post_id: params[:post_id])

    # The permalink calculates pagination for the viewer, including moderation.
    redirect_to thredded.post_permalink_path(record), status: :moved_permanently
  end

  def category
    group = resolve(Thredded::MessageboardGroup.all, "category", params[:category_id])
    redirect_to thredded.show_messageboard_group_path(group), status: :moved_permanently
  end

  private

  def board
    @board ||= resolve(Thredded::Messageboard.all, "forum", params[:forum_id])
  end

  def discussion
    @discussion ||= resolve(board.topics, "topic", params[:topic_id])
  end

  def resolve(scope, kind, value)
    # Never interpret a new Thredded primary key as a legacy mapping.
    mapping = "forem_#{kind}_id"
    if value.to_s.match?(/\A[1-9]\d*\z/)
      record = scope.find_by(mapping => value)
      return record if record
    end
    record = scope.where.not(mapping => nil).find_by(forem_slug: value)
    return record if record

    # Retain FriendlyId's older slugs without loading retired Forem classes.
    ids = FriendlyId::Slug.where(sluggable_type: "Forem::#{kind.camelize}", slug: value).select(:sluggable_id)
    matches = scope.where(mapping => ids).limit(2).to_a
    return matches.first if matches.one?

    raise ActiveRecord::RecordNotFound
  end
end
