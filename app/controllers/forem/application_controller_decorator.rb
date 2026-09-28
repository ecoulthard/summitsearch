if defined?(Forem::ApplicationController)
  Forem::ApplicationController.class_eval do
    skip_before_action :authenticate_user!, only: [:index, :show, :search], raise: false
    skip_before_action :editor_required, raise: false
    skip_before_action :admin_required, raise: false

    after_action :logForemIpAddress, only: :index
    after_action :logForemVisit, only: :show

    def logForemIpAddress
      return if !valid_browser?(request.user_agent)

      user_id = user_signed_in? ? current_user.id : nil
      LogForemVisitWorker.perform_async(request.user_agent, request.remote_ip, user_id, Time.current, nil, nil) if defined?(LogForemVisitWorker)
    end

    def logForemVisit
      return if !valid_browser?(request.user_agent)

      user_id = user_signed_in? ? current_user.id : nil
      record_class = record_id = nil
      record_class = record.class.to_s unless record.nil?
      record_id = record.id unless record.nil?
      LogForemVisitWorker.perform_async(request.user_agent, request.remote_ip, user_id, Time.current, record_class, record_id) if defined?(LogForemVisitWorker)
    end

    private

    #Load and return the record provided in the params.
    def record
      "Forem::#{controller_name.singularize.camelize}".constantize.find(params[:id])
    end

  end
end
