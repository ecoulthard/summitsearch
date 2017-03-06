class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :editor_required
  skip_before_filter :admin_required
  
  layout 'nomenu'
  
  cache_sweeper :user_sweeper

  def destroy
  end

  protected

 #Tells devise where to redirect after updating the users profile.
  def after_update_path_for(resource)
    resource
  end

  def after_inactive_sign_up_path_for(resource)
    if !request.referrer.nil? && request.referrer != main_app.new_user_session_url
      request.referer || stored_location_for(resource) || root_path
    else
      super
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:username, :realname, :country, :province, :city, :email, :password, :password_confirmation)
  end
 
  def account_update_params
    params.require(:user).permit(:username, :realname, :country, :province, :city, :description, :home_page, :photo, :photo_caption, :signature, :email, :password, :password_confirmation, :current_password)
  end
end
