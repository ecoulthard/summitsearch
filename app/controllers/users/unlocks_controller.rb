class Users::UnlocksController < Devise::UnlocksController
  skip_before_action :editor_required, raise: false
  skip_before_action :admin_required, raise: false
  layout 'nomenu'
end
