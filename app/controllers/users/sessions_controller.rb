class Users::SessionsController < Devise::SessionsController
  skip_before_filter :editor_required
  skip_before_filter :admin_required

  layout 'nomenu'

  cache_sweeper :user_sweeper

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
