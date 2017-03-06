#rails runner script/parse_mountains.rb
# Create a new file and write to it  
referrence_string = "Coordinates and Elevation of this unnamed peak was obtained from Googles <a href=\\\"http://code.google.com/apis/maps/documentation/elevation/index.html\\\">Elevation Api Service</a>."
File.open('script/load_unnamed_mountains.rb', 'w') do |file|  
  file.puts "Mountain.transaction do"
  Feature.find_all_by_name_status("Unnamed").each do |feature|
    latitude = feature.latitude
    longitude = feature.longitude
    max_elevation = 0
    locations = ""
    1.upto(8) do |j|
      1.upto(8) do |k|
        locations += "#{latitude-0.004 + 0.001*j},#{longitude-0.004 + 0.001*k}\\|"
      end
    end
    locations = locations[0..locations.length-3]
    page = `wget -q -O- http://maps.googleapis.com/maps/api/elevation/json?locations=#{locations}\\&sensor=false`
    elevation_index = 0
    1.upto(64) do |j|
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
    1.upto(8) do |j|
      1.upto(8) do |k|
        locations += "#{latitude-0.0004 + 0.0001*j},#{longitude-0.0004 + 0.0001*k}\\|"
      end
    end
    locations = locations[0..locations.length-3]
    page = `wget -q -O- http://maps.googleapis.com/maps/api/elevation/json?locations=#{locations}\\&sensor=false`
    elevation_index = 0
    1.upto(64) do |j|
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
    file.puts "  Mountain.create(:name => \"Unnamed #{latitude.round(4)},#{longitude.round(4)}\", :latitude => #{latitude}, :longitude => #{longitude}, :name_status => \"Unnamed\", :height => #{max_elevation}, :referrences => \"#{referrence_string}\", :insert_id => 1)"
    puts "id: #{feature.id}, latitude: #{feature.latitude}, longitude: #{feature.longitude}"
    break if feature.id % 8 == 0
  end
  file.puts "end"
end
