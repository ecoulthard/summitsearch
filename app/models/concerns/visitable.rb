require 'active_support/concern'

module Concerns
  module Visitable
    extend ActiveSupport::Concern

    included do
      has_many :visits, :as => :visitable, :dependent => :destroy
      has_many :likes, -> { where("facebook_like=true OR google_plus=true") }, :as => :visitable, :class_name => "Visit"
      has_many :visitors, :through => :visits, :source => :ip_address
      has_many :recent_visits, -> { where("current_visited_at > ?", 30.minutes.ago) }, :as => :visitable, :class_name => "Visit"
      has_many :recent_visitors, :through => :recent_visits, :source => :ip_address
    end

    def visit_for(ip_address)
      visits.find_by_ip_address_id(ip_address.id)
    end

    # Track when ip last visited articles
    def register_visit_by(ip_address)
      return unless ip_address

      visit = visits.where(ip_address_id: ip_address.id).first_or_create
      visit.increment!("count")

      # update current visited at if more than 15 minutes ago
      if visit.current_visited_at.nil?
	visit.past_visited_at = visit.current_visited_at = Time.now
      end

      if visit.current_visited_at < 15.minutes.ago
	visit.past_visited_at    = visit.current_visited_at
	visit.current_visited_at = Time.now
	visit.save
      end
    end
  end
end
