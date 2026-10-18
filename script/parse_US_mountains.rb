#rails runner script/parse_US_mountains.rb
# Create a new file and write to it  
referrence_string = "Mountain name provided by U.S. Geological Survey Department of the Interior/USGS<br>Elevation was obtained from Googles <a href=\\\"http://code.google.com/apis/maps/documentation/elevation/index.html\\\">Elevation Api Service</a>."
File.open('script/load_Wyoming_mountains.rb', 'a') do |file|  
#file.puts "Mountain.transaction do"
  inFile = File.open('data/Wyoming.txt', 'r')
  name = state = ""
  latitude = longitude = 0
  max_elevation = -0.01
  lineCount = 0
  types = []
  while line = inFile.gets
    lineCount += 1
    line.split('|').each_with_index do |string, i|
      case i % 9
        when 0 then
          name = string
        when 1 then
          status = string
        when 4 then
          state = string
        when 5 then
          latitude = string.to_f
	  break if latitude == 0.0
        when 6 then
          longitude = string.to_f
	  break if longitude == 0.0
        when 7 then
	  max_elevation = string == "\&nbsp;" ? -0.01 : string.to_f
	  max_elevation *= 0.3048 #Convert feet to meters
	  locations = ""
	  1.upto(5) do |j|
	    1.upto(5) do |k|
	      locations += "#{latitude-0.004 + 0.0016*j},#{longitude-0.004 + 0.0016*k}\\|"
	    end
	  end
	  locations = locations[0..locations.length-3]
	  page = ""
	  while page.length == 0
	    page = `wget -q -O- http://maps.googleapis.com/maps/api/elevation/json?locations=#{locations}\\&sensor=false`
	  end

	  googleFile = File.open('google_coordinates.txt', 'w')
	  googleFile.puts(page)
	  googleFile.close

	  elevation_index = 0
	  1.upto(25) do |j|
	    latitude_index = page.index("\"lat\": ", elevation_index) + 7
	    lat = page[latitude_index .. page.index(",", latitude_index)-1].to_f
	    longitude_index = page.index("\"lng\": ", latitude_index) + 7
	    lon = page[longitude_index .. page.index("\n", longitude_index)-1].to_f
	    elevation_index = page.index("\"elevation\": ", longitude_index) + 13
	    elevation = page[elevation_index .. page.index("\n", elevation_index)-1].to_f
	    if elevation > max_elevation
	      max_elevation = elevation
	      latitude = lat
	      longitude = lon
	    end
	  end
	  locations = ""
	  1.upto(5) do |j|
	    1.upto(5) do |k|
	      locations += "#{latitude-0.0004 + 0.00016*j},#{longitude-0.0004 + 0.00016*k}\\|"
	    end
	  end
	  locations = locations[0..locations.length-3]
	  page = ""
	  while page.length == 0
	    page = `wget -q -O- http://maps.googleapis.com/maps/api/elevation/json?locations=#{locations}\\&sensor=false`
	  end
	  googleFile = File.open('google_coordinates.txt', 'w')
	  googleFile.puts(page)
	  googleFile.close

	  elevation_index = 0
	  1.upto(25) do |j|
	    latitude_index = page.index("\"lat\": ", elevation_index) + 7
	    lat = page[latitude_index .. page.index(",", latitude_index)-1].to_f
	    longitude_index = page.index("\"lng\": ", latitude_index) + 7
	    lon = page[longitude_index .. page.index("\n", longitude_index)-1].to_f
	    elevation_index = page.index("\"elevation\": ", longitude_index) + 13
	    elevation = page[elevation_index .. page.index("\n", elevation_index)-1].to_f
	    if elevation > max_elevation
	      max_elevation = elevation
	      latitude = lat
	      longitude = lon
	    end
	  end
	  file.puts "  Mountain.create(:name => \"#{name}\", :latitude => #{latitude}, :longitude => #{longitude}, :name_status => \"Official\", :province => \"#{state}\", :height => #{max_elevation}, :referrences => \"#{referrence_string}\", :insert_id => 1)"
      end
    end
    puts "#{lineCount}, #{name}" if lineCount % 20 == 0
  end
  file.puts "end"
end
