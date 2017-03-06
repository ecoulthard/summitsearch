class Visit < ActiveRecord::Base
  before_create :set_visited_at_to_now

  belongs_to :visitable, :polymorphic => true
  belongs_to :ip_address

  validates :visitable_id,   :presence => true
  validates :visitable_type, :presence => true
  
#attr_accessible :ip_address, :facebook_like, :google_plus, :visit_count, :current_visited_at

  def visited_at
    updated_at
  end

  #The visited record
  def record
    visitable_type.constantize.find(visitable_id)
  end

  private

  def set_visited_at_to_now
    self.current_visited_at = Time.now
    self.past_visited_at = current_visited_at
  end

end
