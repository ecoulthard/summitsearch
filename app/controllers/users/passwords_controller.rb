class Users::PasswordsController < Devise::PasswordsController
  skip_before_filter :editor_required
  skip_before_filter :admin_required
  layout 'nomenu'

  cache_sweeper :user_sweeper
end
