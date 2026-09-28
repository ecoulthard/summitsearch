class Users::SessionsController < Devise::SessionsController
  skip_before_action :editor_required, raise: false
  skip_before_action :admin_required, raise: false

  layout 'nomenu'

  def after_sign_in_path_for(resource)
    if !request.referrer.nil? && request.referrer != main_app.new_user_session_url
      request.referer || stored_location_for(resource) || root_path
    else
      super
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    if !request.referrer.nil?
      request.referer || root_path
    else
      super
    end
  end


end
