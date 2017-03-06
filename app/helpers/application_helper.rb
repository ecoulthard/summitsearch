module ApplicationHelper

  def ie7
    request.user_agent && request.user_agent.match(/msie 7.0/i)
  end

  #Returns the string for the number in nst, nnd, nrd or nth.
  def nth(n)
    if n > 9 and n.to_s[-2..-1].to_i.between?(10,19)
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

  #Print out a datestring for a possibly null month and day
  def partial_date_string(year, month, day)
    if !day.nil?
      "on #{Date::MONTHNAMES[month]}, #{day} of #{year}"
    elsif !month.nil?
      "in #{Date::MONTHNAMES[month]} of #{year}"
    else
      "in #{year}"
    end
  end

  #Cache helper that allows cache conditions
  def cache_if (condition, name = {}, options = nil, &block)
    if condition
      ss_cache(name, options, &block)
    else
      yield
    end
    return nil
  end

  #ss_cache calls cache with skip_digest set to true.
  def ss_cache (name = {}, options = {}, &block)
    cache(name, options.merge!(skip_digest: true), &block)
  end

  #Returns a menu for the application layout
  def menu
    Rails.cache.fetch('menu') { render :partial => 'all/menu' }
  end

  def mark_required(object, attribute)  
    "*" if object.class.validators_on(attribute).map(&:class).include? ActiveModel::Validations::PresenceValidator  
  end

  def localhost
    request.remote_ip == "127.0.0.1"
  end
  
  #returns the mytopo tag using our mytopo id and secret key
  def mytopo_data
#if localhost
      content_tag "div", id: "trimble-data", data: {partner_id: ENV['MY_TOPO_PARTNER_ID'], hash: Digest::MD5.hexdigest(ENV['MY_TOPO_HEX_DIGEST'] + clientip)} do end
#else
#raw "<script type=\"text/javascript\" src=\"http://www.mytopo.com/TileService/Scripts/trimble.mytopo.v3.js?partnerID=ENV['MY_TOPO_PARTNER_ID']&hash=#{ Digest::MD5.hexdigest(ENV['MY_TOPO_HEX_DIGEST'] + clientip) }\"></script>"
#end
  end

  require 'socket'
  def local_ip
    Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
  end


  #Returns the clients ip or our ip if we are in development mode
  def clientip
     localhost ? local_ip : request.remote_ip
  end

  def topo_map_link(lat, long, zoom)
    link_to "Topo Map View", "http://www.mappingsupport.com/p/gmap4.php?ll=" + lat.to_s + "," + long.to_s + "&z=" + zoom.to_s + "&t=t2&ll=" + lat.to_s + "," + long.to_s, :rel => 'nofollow', :class => 'linkButton'
  end

  def google_map_include_tag
    if localhost
      raw "<script type=\"text/javascript\" src=\"https://maps.googleapis.com/maps/api/js?libraries=geometry&key=" + ENV['GOOGLE_MAPS_API_KEY']  + "\"></script>"
    else
      raw "<script type=\"text/javascript\" src=\"https://maps.googleapis.com/maps/api/js?libraries=geometry\"></script>"
    end
  end

  #Define role identification functions
  User::ROLES.each_with_index do |role, index|
    define_method("user_is_#{role.downcase}?") { user_signed_in? && current_user.send("is_#{role.downcase}?") } unless method_defined? "user_is_#{role.downcase}?"
  end

    RADIUS_EARTH = 6378.1

  def distance lat1, lon1, lat2, lon2
    r = RADIUS_EARTH #Earths Radius in km
    dLat = Place.to_rad(lat2-lat1)
    dLon = Place.to_rad(lon2-lon1)
    a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(Place.to_rad(lat1)) * Math.cos(Place.to_rad(lat2)) * Math.sin(dLon/2) * Math.sin(dLon/2)
c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    d = r * c
  end

end
