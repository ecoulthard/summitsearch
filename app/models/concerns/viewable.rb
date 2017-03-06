require 'active_support/concern'

module Concerns
  module Viewable
    extend ActiveSupport::Concern

    included do
      has_many :views, :as => :viewable, :dependent => :destroy
      has_many :user_likes, -> { where("rating > 0") }, :as => :viewable, :class_name => "View"
      has_many :fans, :through => :user_likes, :source => :user
      has_many :recent_views, -> { where("current_viewed_at > ?", 30.minutes.ago) }, :as => :viewable, :class_name => "View"
      has_many :recent_viewers, :through => :recent_views, :source => :user

      #Has the user rated the viewable already
      def has_rated user
	user_view = views.find_by_user_id(user.id)
	!user_view.nil? && !user_view.rating.nil?
      end
    end

    def view_for(user)
      views.find_by_user_id(user.id)
    end

    # Track when users last viewed topics
    def register_view_by(user)
      return unless user

      view = views.where(user_id: user.id).first_or_create
      view.increment!("count")

      # update current viewed at if more than 15 minutes ago
      if view.current_viewed_at.nil?
	view.past_viewed_at = view.current_viewed_at = Time.now
      end

      if view.current_viewed_at < 15.minutes.ago
	view.past_viewed_at    = view.current_viewed_at
	view.current_viewed_at = Time.now
	view.save
      end
    end
  end
end
