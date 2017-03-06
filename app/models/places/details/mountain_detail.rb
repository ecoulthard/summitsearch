class MountainDetail < ActiveRecord::Base
  belongs_to :mountain, class_name: "Mountain", inverse_of: :detail
  belongs_to :parent_mountain, class_name: "Mountain"

  scope :order_by_isolation, -> { order('dist_to_parent DESC') }
end
