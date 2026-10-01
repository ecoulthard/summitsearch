module ApplicationHelper

  def ie7
    request.user_agent && request.user_agent.match(/msie 7.0/i)
  end

  def facebookAppId
    Rails.application.config.facebook_app_id 
  end

  # Returns the string for the number in nst, nnd, nrd or nth.
  def nth(n)
    if n > 9 && n.to_s[-2..-1].to_i.between?(10, 19)
      "#{n}th"
    elsif n.to_s[-1].to_i == 1
      "#{n}st"
    elsif n.to_s[-1].to_i == 2
      "#{n}nd"
    elsif n.to_s[-1].to_i == 3
      "#{n}rd"
    else
      "#{n}th"
    end   
  end

  # Print out a datestring for a possibly null month and day
  def partial_date_string(year, month, day)
    if !day.nil?
      "on #{Date::MONTHNAMES[month]}, #{day} of #{year}"
    elsif !month.nil?
      "in #{Date::MONTHNAMES[month]} of #{year}"
    else
      "in #{year}"
    end
  end

  # Cache helper that allows cache conditions
  def cache_if(condition, name = {}, options = nil, &block)
    if condition
      ss_cache(name, options || {}, &block)
    else
      yield
    end
  end

  # ss_cache calls cache with skip_digest set to true.
  def ss_cache(name = {}, options = {}, &block)
    options = (options || {}).merge(skip_digest: true)
    cache(name, options, &block)
  end

  # Returns a menu for the application layout
  def menu
    Rails.cache.fetch('menu') { render partial: 'all/menu' }
  end

  def mark_required(object, attribute)  
    "*" if object.class.validators_on(attribute).map(&:class).include? ActiveModel::Validations::PresenceValidator  
  end

  def localhost
    request.remote_ip == "127.0.0.1"
  end
  
  # returns the mytopo tag using our mytopo id and secret key
  def mytopo_data
    partner_id = Rails.application.config.my_topo_partner_id.to_s
    secret_hex = Rails.application.config.my_topo_hex_digest.to_s
    content_tag "div", id: "trimble-data", data: { partner_id: partner_id, hash: Digest::MD5.hexdigest(secret_hex + clientip) } do end
  end

  require 'socket'
  def local_ip
    Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }&.ip_address || "127.0.0.1"
  end

  # Returns the clients ip or our ip if we are in development mode
  def clientip
     localhost ? local_ip : request.remote_ip
  end

  def topo_map_link(lat, long, zoom)
    link_to "Topo Map View", "http://www.mappingsupport.com/p/gmap4.php?ll=#{lat},#{long}&z=#{zoom}&t=t2&ll=#{lat},#{long}", rel: 'nofollow', class: 'linkButton'
  end

  def google_map_include_tag
    api_key = Rails.application.config.google_maps_api_key.presence || ENV["GOOGLE_MAPS_API_KEY"].presence
    key_param = api_key ? "&key=#{api_key}" : ""
    raw "<script type=\"text/javascript\" src=\"https://maps.googleapis.com/maps/api/js?libraries=geometry#{key_param}\"></script>"
  end

  # Define role identification functions
  User::ROLES.each_with_index do |role, index|
    define_method("user_is_#{role.downcase}?") { user_signed_in? && current_user.send("is_#{role.downcase}?") } unless method_defined? "user_is_#{role.downcase}?"
  end

  def distance(lat1, lon1, lat2, lon2)
    GeographyHelper.distance(lat1, lon1, lat2, lon2)
  end
end

class ActionView::Helpers::FormBuilder
  def link_to_add(name, association, **options)
    @template.link_to(name, "javascript:void(0)", options.merge(data: { association: association }, class: [options[:class], "add_nested_fields"].compact.join(" ")))
  end

  def link_to_remove(name, **options)
    @template.link_to(name, "javascript:void(0)", options.merge(class: [options[:class], "remove_nested_fields"].compact.join(" ")))
  end
end
