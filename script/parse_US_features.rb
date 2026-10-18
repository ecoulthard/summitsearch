#rails runner script/parse_mountains.rb
# Create a new file and write to it  
referrence_string = "Mountain name provided by U.S. Geological Survey Department of the Interior/USGS<br>Elevation was obtained from Googles <a href=\\\"http://code.google.com/apis/maps/documentation/elevation/index.html\\\">Elevation Api Service</a>."
fclass = Waterfall
ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
File.open('script/load_US_falls.rb', 'a') do |file|  
  inFile = File.open('data/USFalls.txt', 'r')
  name = status = type = province = decision_date = ""
  latitude = longitude = 0
  max_elevation = -0.01
  lineCount = 0
  features = []
  while line = inFile.gets
    line.split('|').each_with_index do |string, i|
      case i % 11
        when 0 then
	  features[lineCount % 50] = fclass.new
          features[lineCount % 50].name = string
        when 1 then
          features[lineCount % 50].name_status = "Official"
        when 4 then
          features[lineCount % 50].province = string
        when 5 then
          latitude = string.to_f
          features[lineCount % 50].latitude = latitude
	  break if latitude == 0.0
        when 6 then
          longitude = string.to_f
          features[lineCount % 50].longitude = longitude
	  break if longitude == 0.0
        when 7 then
	  elevation = string == "\&nbsp;" ? -0.01 : string.to_f
	  elevation *= 0.3048 #Convert feet to meters
          features[lineCount % 50].height = elevation 
      end
    end
    lineCount += 1
    if lineCount % 50 == 0 || inFile.eof?
      locations = ""
      features.each do |feature|
	locations += "#{feature.latitude},#{feature.longitude}\\|"
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
      features.each do |feature|
	elevation_index = page.index("\"elevation\" : ", elevation_index) + 13
	elevation = page[elevation_index .. page.index("\n", elevation_index)-1].to_f
	elevation_index += 1
	file.puts "  #{fclass.to_s}.create(:name => \"#{feature.name}\", :latitude => #{feature.latitude}, :longitude => #{feature.longitude}, :name_status => \"#{feature.name_status}\", :province => \"#{feature.province}\", :height => #{elevation}, :referrences => \"#{referrence_string}\", :insert_id => 1)"
      end
      puts "#{lineCount}, #{name}"
      features = [] #Clear array for next batch
    end
  end
end
