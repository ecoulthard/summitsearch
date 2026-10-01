module Forem
  module ApplicationHelper
    # Returns a menu for the application layout
    def forem_menu
      render partial: 'forem/all/menu'
    end

    def recent_users
      if @category.present?
        @category.recent_viewers
      elsif @forum.present?
        @forum.recent_viewers
      elsif @topic.present?
        @topic.recent_viewers
      else
        User.where("forem_last_visit_at > ?", 30.minutes.ago)
      end
    end

    def recent_guest
      if @category.present?
        @category.recent_visitors.where("user_id IS NULL")
      elsif @forum.present?
        @forum.recent_visitors.where("user_id IS NULL")
      elsif @topic.present?
        @topic.recent_visitors.where("user_id IS NULL")
      else
        IpAddress.where("user_id IS NULL AND forem_last_visit_at > ?", 30.minutes.ago)
      end
    end

    def total_recent
      recent_users.count + recent_guest.count
    end

    def newest_member
      User.where.not(forem_first_visit_at: nil).order(forem_first_visit_at: :desc).first
    end
  end
end
