module DeviseHelper
  def devise_error_messages!
    return "" unless devise_error_messages?

    render "devise/shared/error_messages", resource: resource
  end

  def devise_error_messages?
    !resource.errors.empty?
  end
end
