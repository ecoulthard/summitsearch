if defined?(Forem) && defined?(Forem::Category)
  Forem::Category.class_eval do
    include Concerns::Visitable

    has_many :recent_viewers, :through => :forums
  end
end
