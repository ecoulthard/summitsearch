class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include ApplicationHelper
  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
  end

  before_action :valid_user_agents
  before_action :enable_tracking
  before_action :authenticate_user!, except: [:index, :show], raise: false
  before_action :editor_required, except: [:index, :show, :expire], raise: false
  before_action :admin_required, except: [:index, :show, :edit, :update, :new, :create, :expire], raise: false
  protect_from_forgery

  def forem_user
    current_user
  end

  def user_signed_in?
    defined?(super) ? super : (respond_to?(:current_user) && current_user.present?)
  end

  def current_user
    defined?(super) ? super : @current_user
  end

  def user_is_admin?
    user_signed_in? && current_user.is_admin?
  end

  def authenticate_user!
    defined?(super) ? super : (user_signed_in? ? true : permission_denied)
  end

  helper_method :forem_user, :user_signed_in?, :current_user, :user_is_admin?

  def current_ability
    defined?(Forem::Ability) ? Forem::Ability.new(forem_user) : nil
  end

  layout 'application'

  #  #Increment the number of access for this ip address
  #  #If there is a signed in user then record their id in the IpAddress record
  #  def logIpAddress
  #    #return if the request is not from a well used browser
  #    return if !valid_browser?(request.user_agent)
  #    ip_address = IpAddress.find_by_address(request.remote_ip) #Seen this address yet?
  #    user_id = user_signed_in? ? current_user.id : nil
  #    if ip_address.nil?
  #      ip_address = IpAddress.create(:address => request.remote_ip, :user_id => user_id, :visit_count => 1, :first_visit_at => Time.now, :last_visit_at => Time.now, :last_http_user_agent => request.user_agent)
  #    else
  #      ip_address.visit_count += 1
  #      ip_address.last_visit_at = Time.now
  #      ip_address.user_id = user_id unless user_id.nil?
  #      ip_address.last_http_user_agent = request.user_agent
  #      ip_address.save
  #    end
  #    ip_address
  #  end

  #Increment a visit count for this ip address for the given record
  #Called by show actions of Albums,Places,Photos,Routes and TripReports
  def logVisit record=nil, rateable=false
    return if !valid_browser?(request.user_agent) or valid_robot?(request.user_agent)

    user_id = user_signed_in? ? current_user.id : nil
    record_class = record_id = nil
    record_class = record.class.to_s unless record.nil?
    record_id = record.id unless record.nil?
    LogVisitWorker.perform_async(request.user_agent, request.remote_ip, user_id, Time.now, record_class, record_id, rateable) if defined?(LogVisitWorker)
  end

  protected

  VALID_BROWSERS = ["applewebkit", "blackberry", "chrome", "firefox", "gecko", "msie", "netscape", "opera", "playstation", "safari", "trident", "wii", "dolfin"]
  VALID_ROBOTS = ["google", "msnbot", "slurp", "teoma", "facebook"]

  #Returns true if the user_agent is from a valid browser
  def valid_browser? user_agent
    !user_agent.blank? && VALID_BROWSERS.any? {|browser| user_agent.downcase.include? browser }
  end

  #Returns true if the user_agent is from a valid robot
  def valid_robot? user_agent
    !user_agent.blank? && VALID_ROBOTS.any? {|robot| user_agent.downcase.include? robot }
  end

  def valid_user_agents
    if !request.user_agent.blank? && (request.user_agent.include?("MSIE 6.") || request.user_agent.include?("MSIE 5.") || request.user_agent.include?("MSIE 4."))
      redirect_to 'http://http://www.ie6countdown.com'
      return false
    end
  end

  #Enable do not track for certain users or ip addresses.
  def enable_tracking
    @DoNotTrack = false
    #Enable do not track for admin and any future employees. Har har. Employees. Yah right.
    if user_signed_in? && current_user.is_admin?
      @DoNotTrack = true
    end
    true
  end

  #Access denied to search engines
  def browsers_only
    if !valid_browser?(request.user_agent) or valid_robot?(request.user_agent)
      respond_to do |format|
        format.html { render :file => Rails.root.join("public/401.html"), :status => :unauthorized, :layout => false }
        format.xml do
          headers["Status"] = "Unauthorized"
          render :plain => "You appear to be a robot. No robots are allowed to access this page.", :status => :unauthorized
        end
      end
    end
  end

  if defined?(User) && defined?(User::ROLES)
    User::ROLES.each do |role|
      define_method("#{role.downcase}_required") { user_signed_in? && current_user.send("is_#{role.downcase}?") ? true : permission_denied } unless method_defined? "#{role.downcase}_required"
    end
  end

  #Access denied to non contributers
  def non_contributer_access_denied
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, :notice => "You need to be a contributor to access this page. You can contribute trip reports, routes or photos to the site to gain access.") }
      format.xml do
        headers["Status"]           = "Unauthorized"
        headers["WWW-Authenticate"] = %(Basic realm="Web Password")
        render :plain => "You need to be a contributor to access this page. You can contribute trip reports, routes or photos to the site to gain access.", :status => :unauthorized
      end
    end
  end

  def permission_denied
    respond_to do |format|
      format.html { redirect_to(root_path, :notice => "You don't have permission to complete that action.") }
      format.xml do
        headers["Status"]           = "Unauthorized"
        headers["WWW-Authenticate"] = %(Basic realm="Web Password")
        render :plain => "You don't have permission to complete this action.", :status => :unauthorized
      end
    end
  end

  #Called to expire the index action of places, trip reports and whatnot.
  def expire_index
    controller_class = controller_name.singularize.camelize.constantize
    if params[:type].blank?
      expire_fragment(action: :index)
      controller_class::SORT_OPTIONS.keys.sort.each do |sort|
        expire_fragment(action: :index, sort: sort)
      end
      respond_to do |format|
        format.html { redirect_to(action: "index") }
        format.xml  { head :ok }
      end
    else
      subclass = params[:type].to_s.safe_constantize
      if subclass && subclass <= controller_class
        expire_fragment(send("#{subclass.to_s.tableize}_url", place_id: params[:place_id])[7..-1])
        controller_class::SORT_OPTIONS.keys.sort.each do |sort|
          expire_fragment(send("#{subclass.to_s.tableize}_url", sort: sort, place_id: params[:place_id])[7..-1])
        end
        respond_to do |format|
          format.html { redirect_to(send("#{subclass.to_s.tableize}_url", sort: params[:sort], place_id: params[:place_id])) }
          format.xml  { head :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to(action: "index") }
          format.xml  { head :ok }
        end
      end
    end
  end
end
