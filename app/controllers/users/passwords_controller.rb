class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :editor_required, raise: false
  skip_before_action :admin_required, raise: false
  layout 'nomenu'
end
