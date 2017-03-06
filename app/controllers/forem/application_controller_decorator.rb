Forem::ApplicationController.class_eval do
  skip_before_filter :authenticate_user!, :only => [:index, :show, :search]
  skip_before_filter :editor_required
  skip_before_filter :admin_required

  after_filter :logForemIpAddress, :only => :index
  after_filter :logForemVisit, :only => :show

  def logForemIpAddress
    return if !valid_browser?(request.user_agent)

    user_id = user_signed_in? ? current_user.id : nil
    LogForemVisitWorker.perform_async(request.user_agent, request.remote_ip, user_id, Time.now, nil, nil)
  end

  def logForemVisit
    return if !valid_browser?(request.user_agent)

    user_id = user_signed_in? ? current_user.id : nil
    record_class = record_id = nil
    record_class = record.class.to_s unless record.nil?
    record_id = record.id unless record.nil?
    LogForemVisitWorker.perform_async(request.user_agent, request.remote_ip, user_id, Time.now, record_class, record_id)
  end

  private

  #Load and return the record provided in the params.
  def record
    "Forem::#{controller_name.singularize.camelize}".constantize.find(params[:id])
  end

end
