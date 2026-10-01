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
      LogForemVisitJob.perform_later(request.user_agent, request.remote_ip, user_id, Time.current, nil, nil)
    end

    def logForemVisit
      return if !valid_browser?(request.user_agent)

      user_id = user_signed_in? ? current_user.id : nil
      record_class = record_id = nil
      record_class = record.class.to_s unless record.nil?
      record_id = record.id unless record.nil?
      LogForemVisitJob.perform_later(request.user_agent, request.remote_ip, user_id, Time.current, record_class, record_id)
    end

    private

    #Load and return the record provided in the params.
    def record
      "Forem::#{controller_name.singularize.camelize}".constantize.find(params[:id])
    end

  end
end
