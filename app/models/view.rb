class View < ActiveRecord::Base
  before_create :set_viewed_at_to_now

  belongs_to :viewable, :polymorphic => true
  belongs_to :user, :class_name => Forem.user_class.to_s

  validates :viewable_id,   :presence => true
  validates :viewable_type, :presence => true

#attr_accessible :user, :current_viewed_at, :count, :rating

  def viewed_at
    updated_at
  end

  private

  def set_viewed_at_to_now
    self.current_viewed_at = Time.now
    self.past_viewed_at = current_viewed_at
  end

end
