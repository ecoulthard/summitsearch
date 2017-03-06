Forem::Group.class_eval do
  include Concerns::Visitable

  has_many :recent_viewers, :through => :forums
end
