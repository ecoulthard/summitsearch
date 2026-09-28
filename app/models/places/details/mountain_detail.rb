class MountainDetail < ApplicationRecord
  belongs_to :mountain, class_name: "Mountain", inverse_of: :detail, optional: true
  belongs_to :parent_mountain, class_name: "Mountain", optional: true

  scope :order_by_isolation, -> { order('dist_to_parent DESC') }
end
