require 'integration_test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  include ActionView::Helpers::UrlHelper
  fixtures :all
  fixtures :features

  def setup

  end

  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "Register a User" do
    visit '/users/sign_up'
    within("#new_user") do
      fill_in 'Email', :with => 'luke@skywalker.com'
      fill_in 'Password', :with => '12345678'
      fill_in 'Confirm', :with => '12345678'
      fill_in 'Username', :with => 'sluke'
      fill_in 'Realname', :with => 'Luke Skywalker'
    end
    click_button 'Sign up'
  end

  #A person goes to the site to upload a photo
  #Since they are not logged in they first go to the login page and enter their info
  #After logging in they are taken to the new photo page.
  #From the main page they search for "Mount Columbia" which they wish to upload to.
  #They click on the mountain page and then on the insert link for photos
  #They fill in the fields and submit the photo.
  #They are then redirected to the photo show page for their photo.
  #The photo should have links to any features mentioned
  #
  test "Uploading a photo" do
#    visit '/users/sign_in' #Got to main page
#    within("#new_user") do
#      fill_in 'Email', :with => 'darth@vador.com'
#      fill_in 'Password', :with => '123456'
#    end
#    click_button 'Sign in'
#    assert_equal current_path, root_path
#    assert page.has_content?('Signed in successfully')
#    fill_in 'search', :with => 'Mount Columbia'
    #Since this driver doesn't do javascript we skip pressing enter in the textfield.
#    visit(search_path(:search => 'Mount Columbia'))
#    assert_equal current_path, feature_path(features(:columbia))
#    assert page.has_content?('Mount Columbia')
#    click_link 'Insert a Photo'
#    assert_equal current_path, new_photo_path.gsub(".", "/")
#    fill_in('Title', :with => 'Mount Saskatchewan and Castleguard Mountain')
#    attach_file('photo_photo', '/home/vador/Pictures/2009/Mount_Columbia/Summit_Day/IMG_3042.JPG')
#    fill_in('photo_time', :with => 'May 10 2009 at 5pm')
#    fill_in('photo_height', :with => '3026')
#    fill_in('photo_latitude', :with => '52.142985325972845')
#    fill_in('photo_longitude', :with => '-117.42321655273437')
#    fill_in('photo_vantage', :with => 'From Mount Columbia')
#    fill_in('photo_caption', :with => 'Mount Saskatchewan and Castleguard Mountain to the southeast from the Columbia Icefield west of the trench')
#    fill_in('photo_description', :with => 'I took this photo while returning to camp after successfully reaching the summit of Mount Columbia on an Edmonton Section ACC trip. Our first day in was cloudy during our ascent of the Athabasca Glacier. After reaching the icefield it was a whiteout for the rest of the day. For our ascent day it cleared up in places and was very beautiful. For the final 800 m we couldn\'t see much as clouds were covering Columbia. But when we reached the summit an occasional window to the west would open up revealing many beautiful summits. As we returned the views started improving more and we could start to see the Twins. The day out was spectacular. Not a cloud in the sky when we woke up. The Twins were shimmering in the morning sun. We had a great time skiing down the Athabasca Glacier. Some of my best photos are from the descent down the glacier. Definitely one of the best trips ever for me, if not the best.')
#    click_button 'Create Photo'
#    assert page.has_content?('Photo was successfully created.')
#    assert find_link('Mount Saskatchewan').visible?
#    assert find_link('Castleguard Mountain').visible?
#    assert find_link('Success on Mount Columbia').visible?
  end

  #A person goes to the site to upload a trip report
  #Since they are not logged in they first go to the login page and enter their info
  #After logging in they are taken to the new photo page.
  #From the main page they search for "North Twin" which they wish to upload to.
  #They click on the mountain page and then on the insert link for trips
  #They fill in the fields adding waypoints and submit the trip report.
  #They are then redirected to the show page for their trip.
  #The trip should have links to any photos submitted for it previously.
  test "Uploading a trip report" do
    visit '/users/sign_in' #Got to main page
    within("#new_user") do
      fill_in 'Email', :with => 'darth@vador.com'
      fill_in 'Password', :with => '1234567'
    end
    click_button 'Sign in'
    assert_equal current_path, root_path
    fill_in 'search', :with => 'North Twin'
    #Since this driver doesn't do javascript we skip pressing enter in the textfield.
    #visit(search_path(:search => 'North Twin'))
    #assert_equal feature_path(features(:north_twin)), current_path
    visit(feature_path(features(:north_twin)))
    assert page.has_content?('North Twin')
    click_link 'Insert a Photo'
    assert_equal current_path, new_photo_path.gsub(".", "/")
    fill_in('Title', :with => 'North Twin, Mount Alberta and Stutfield Peak')
    attach_file('photo_photo', 'test/fixtures/gorilla.jpg')
    fill_in('photo_time', :with => 'March 14 2010 at 8am')
    fill_in('photo_height', :with => '3240')
    fill_in('photo_latitude', :with => '52.22116173958155')
    fill_in('photo_longitude', :with => '-117.41584144958495')
    fill_in('photo_vantage', :with => 'From Stutfield Col')
    fill_in('photo_caption', :with => 'The view on Approach to North Twin. North Twin on the left, the Athabasca valley, Mount Alberta and Stutfield Peak.')
    fill_in('photo_description', :with => 'It is a long story. See the trip report.')
    all("input[type='submit']").first.click
    assert page.has_content?('Photo was successfully created.')
    assert all('a', :text => 'North Twin').first.visible?
    assert all('a', :text => 'Mount Alberta').first.visible?
    assert all('a', :text => 'Stutfield Peak').first.visible?

    #Now add trip report.
    all('a', :text => 'North Twin').first.click
    assert page.has_content?('North Twin, Mount Alberta and Stutfield Peak')
    click_link 'Submit a new Trip Report'
    fill_in('route_trip_reports_attributes_0_title', :with => 'North Twin, Mount Alberta and Stutfield Peak')
    fill_in('route_trip_reports_attributes_0_start_time', :with => 'March 12 2010 at 8am')
    fill_in('route_trip_reports_attributes_0_end_time', :with => 'March 15 2010 at 5pm')
    fill_in('route_trip_reports_attributes_0_abstract', :with => 'We were able to ski all the way to the summit on this trip. It is definitely a serious mountain and should only be attempted by experienced parties. On this trip we had ambitious plans to ascend North Twin, South Twin, West Twin and Twins Tower. Due to weather and difficult trail breaking we were not able to reach base camp till the 3rd day.')
    fill_in('route_trip_reports_attributes_0_participants', :with => 'You, Me, She, He')
    fill_in('route_trip_reports_attributes_0_description', :with => 'We started skiing early Friday morning up the Athabasca Glacier. I was the only one without a sled, which was probably better since those sleds were more trouble than they were worth. On the way to the glacier we saw a lot of ptarmigans, at least 14 or more. There was enough snow for us to ski all the way to the glacier, which was way better than carrying them. For the most part the snow was good on the glacier. Just one or two spots with deep powder. We skied beneath the seracs on Snowdome without incident and ascended the ramp into a whiteout. There was a lot of powder slowing down our trail breaking and after about 2 hours we gave up on making it to base camp at Stutfield col and set up camp. This was for the better anyway since we were foolishly not following our gps and were heading in the wrong direction toward the trench. Not making it to base camp meant that we would lose one of our summit days. It snowed heavily on us for the rest of the day.')
    fill_in('route_name', :with => 'North Twin via Athabasca Glacier')
#fill_in('route_equipment', :with => 'Skis, skins, Avi gear, Crampons/Ski Crampons, Ice Ace, rope and crevasse rescue equipment, Winter Camping gear')
    fill_in('route_description', :with => 'Ski up the Athabasca Glacier to the icefields neve. Contour around Snowdome and then traverse North to the camp by Stutfield Col. Ski towards the left side of North Twin and ascent ascend the slopes with skins. Ski crampons may be needed if the snow is wind hardened. If the snow is good enough you can ski right to the summit. Otherwise you may need to walk the summit ridge. Be watchful of crevasses on the summit ridge as there are plenty of them. Ski back down the way you came. Return to the trailhead the same way you came but be sure not to be on the Athabasca Glacier late in the day because of weakened snow bridges.')
    fill_in('Latitude', :with => '52.2197420249697')
    fill_in('Longitude', :with => '-117.22538315185545')
    click_button('Add Waypoint')
    fill_in('Latitude', :with => '52.20217587589444')
    fill_in('Longitude', :with => '-117.24546753295897')
    click_button('Add Waypoint')
    fill_in('Latitude', :with => '52.16670686505061')
    fill_in('Longitude', :with => '-117.28632294067381')
    click_button('Add Waypoint')
    fill_in('Latitude', :with => '52.17049718923302')
    fill_in('Longitude', :with => '-117.32185684570311')
    click_button('Add Waypoint')
    fill_in('Latitude', :with => '52.223107200708014')
    fill_in('Longitude', :with => '-117.40803085693358')
    click_button('Add Waypoint')
    fill_in('Latitude', :with => '52.21742831872597')
    fill_in('Longitude', :with => '-117.4313768041992')
    click_button('Add Waypoint')
    fill_in('Latitude', :with => '52.22521030605203')
    fill_in('Longitude', :with => '-117.43498169311522')
    click_button('Add Waypoint')
    #click_button('Create Trip Report and Route')
    all("input[type='submit']").first.click
#assert page.has_content?('Trip report and Ascent Route were successfully created. You have been granted')
  end

end
