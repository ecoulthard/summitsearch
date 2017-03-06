module GeographyHelper
  RADIUS_EARTH = 6378.1

  #These functions find a bounding box around a given lat long
  def self.maxLatitude lat, radius
    lat + to_deg(radius/RADIUS_EARTH)
  end

  def self.minLatitude lat, radius
    lat - to_deg(radius/RADIUS_EARTH)
  end

  def self.maxLongitude lat, lon, radius
    lon + to_deg(radius/RADIUS_EARTH/Math.cos(to_rad(lat)))
  end 

  def self.minLongitude lat, lon, radius
    lon - to_deg(radius/RADIUS_EARTH/Math.cos(to_rad(lat)))
  end 

  def self.to_rad angle
    angle/180 * Math::PI
  end

  def self.to_deg radians
    radians*180 / Math::PI
  end
  
  #Haversine Formula
  def self.distance lat1, lon1, lat2, lon2
    r = RADIUS_EARTH #Earths Radius in km
    dLat = to_rad(lat2-lat1)
    dLon = to_rad(lon2-lon1)
    a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) * Math.sin(dLon/2) * Math.sin(dLon/2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    d = r * c
  end

  def self.bearing lat1, lon1, lat2, lon2
    dLon = to_rad(lon2-lon1)
    lat1 = to_rad(lat1)
    lat2 = to_rad(lat2)
    y = Math.sin(dLon) * Math.cos(lat2)
    x = Math.cos(lat1)*Math.sin(lat2)-Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon)
    bearing = to_deg(Math.atan2(y, x))
  end

  def self.direction lat1, lon1, lat2, lon2
    bear = bearing(lat1, lon1, lat2, lon2)
    if (bear < 22.5 && bear >= -22.5)
      direction = "North" 
    elsif bear < 67.5 && bear >= 22.5
      direction = "North East" 
    elsif bear < 112.5 && bear >= 67.5
      direction = "East"
    elsif bear < 157.5 && bear >= 112.5
      direction = "South East"
    elsif bear < -157.5 || bear >= 157.5
      direction = "South"
    elsif bear > -157.5 && bear <= -112.5
      direction = "South West"
    elsif bear > -112.5 && bear <= -67.5
      direction = "West"
    elsif bear > -67.5 && bear <= -22.5
      direction = "North West"
    end
  end

end
