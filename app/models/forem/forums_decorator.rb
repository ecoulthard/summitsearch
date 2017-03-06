Forem::Forum.class_eval do
  include Concerns::Visitable

  has_many :recent_views, -> { where("current_viewed_at > ?", 30.minutes.ago) }, :as => :viewable, :class_name => "View"
  has_many :recent_viewers, :through => :recent_views, :source => :user

  has_one :place
end
