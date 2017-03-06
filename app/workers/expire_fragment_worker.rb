#Expires the given fragment
#This is currently broken so don't use until you fix it.
class ExpireFragmentWorker
  include Sidekiq::Worker

  class << self
    include Rails.application.routes.url_helpers
  end

  def perform(controller, action, part)
    ActionController::Base.new.expire_fragment(:controller => controller, :action => action, :part => part)
  end
end
