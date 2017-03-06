Forem::Post.class_eval do
  has_one :album, :through => :topic
  has_one :photo, :through => :topic
  has_one :trip_report, :through => :topic
end
