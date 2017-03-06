class IpAddressesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :editor_required
  before_filter :admin_required

  # GET /ip_addresses
  # GET /ip_addresses.xml
  def index
    @noindex = true #Don't let search engines index this page
    @record_class = @parent_class = IpAddress
    @type = "Ip Address"
    @sort = params[:sort].blank? ? IpAddress::DEFAULT_SORT : params[:sort]
    @records = IpAddress.list(@sort).includes(:user).paginate :page=>params[:page]

    respond_to do |format|
      format.html { render :template => "all/index" }
      format.xml  { render :xml => @records }
    end
  end

  # GET /ip_addresses/1
  # GET /ip_addresses/1.xml
  def show
    @ip_address = IpAddress.find(params[:id])
    @pageTitle = @ip_address.address + " Site History"
    @metaDescription = "Ip Address: " + @ip_address.address
    @trip_report_visit_groups = @ip_address.trip_report_visits.order("updated_at DESC").limit(30).in_groups_of(3)
    @place_visit_groups = @ip_address.place_visits.order("updated_at DESC").limit(30).in_groups_of(3)
    @photo_visits = @ip_address.photo_visits.order("updated_at DESC").limit(30)
    @route_visit_groups = @ip_address.route_visits.order("updated_at DESC").limit(30).in_groups_of(3)
    @album_visit_groups = @ip_address.album_visits.order("updated_at DESC").limit(30).in_groups_of(3)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @ip_address }
    end
  end
end
