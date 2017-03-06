require 'test_helper'

class RoutesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  fixtures :routes
  fixtures :users
  fixtures :places

  setup do
    @admin = users(:vador)
    @editor = users(:akbar)
    @author = users(:author)
    @route = routes(:columbia)
    @route.name = "North Twin Ascent"
  end

  test "should get index" do
    get :index
    assert_response :success
    #assert_not_nil assigns(:routes)
  end

  test "should get new" do
    sign_in @admin
    get :new, :type => 'Scramble', :place_id => places(:columbia).id
    assert_response :success
    sign_out @admin
  end

  test "should create route" do
    sign_in @admin
    route = Route.new(:name => 'North Twin', :name_status => 'Official', :travel_time => 'Unknown', :insert_id => users(:vador).id)
	waypoint1 = route.waypoints.build
	waypoint2 = route.waypoints.build
	waypoint3 = route.waypoints.build
	waypoint4 = route.waypoints.build
	waypoint5 = route.waypoints.build
	waypoint6 = route.waypoints.build
	waypoint7 = route.waypoints.build
	waypoint8 = route.waypoints.build
	waypoint9 = route.waypoints.build
	waypoint10 = route.waypoints.build
	waypoint11 = route.waypoints.build

	waypoint1.latitude = 52.2197420249697
	waypoint1.longitude = -117.22538315185545
	waypoint2.latitude = 52.20217587589444
	waypoint2.longitude = -117.24546753295897
	waypoint3.latitude = 52.16670686505061
	waypoint3.longitude = -117.28632294067381
	waypoint4.latitude = 52.17049718923302
	waypoint4.longitude = -117.32185684570311
	waypoint5.latitude = 52.223107200708014
	waypoint5.longitude = -117.40803085693358
	waypoint6.latitude = 52.21742831872597
	waypoint6.longitude = -117.4313768041992
	waypoint7.latitude = 52.22542831872597
	waypoint7.longitude = -117.43498169311522
	waypoint8.latitude = 52.2337268641058
	waypoint8.longitude = -117.405284274902
	waypoint9.latitude = 52.2427673475595
	waypoint9.longitude = -117.411292423096
	waypoint10.latitude = 52.246235881402
	waypoint10.longitude = -117.402366031494
	waypoint11.latitude = 52.2555890604279
	waypoint11.longitude = -117.395671237793

	waypoint1.local_index = 0
	waypoint2.local_index = 1
	waypoint3.local_index = 2
	waypoint4.local_index = 3
	waypoint5.local_index = 4
	waypoint6.local_index = 5
	waypoint7.local_index = 6
	waypoint8.local_index = 7
	waypoint9.local_index = 8
	waypoint10.local_index = 9
	waypoint11.local_index = 10
	waypoint1.parent_index = -1
	waypoint2.parent_index = 0
	waypoint3.parent_index = 1
	waypoint4.parent_index = 2
	waypoint5.parent_index = 3
	waypoint6.parent_index = 4
	waypoint7.parent_index = 5
	waypoint8.parent_index = 4
	waypoint9.parent_index = 7
	waypoint10.parent_index = 8
	waypoint11.parent_index = 9
	waypoint1.height = 1982
	waypoint2.height = 2156
	waypoint3.height = 2787
	waypoint4.height = 3081
	waypoint5.height = 3230
	waypoint6.height = 3537
	waypoint7.height = 3644
	waypoint8.height = 3358
	waypoint9.height = 3346
	waypoint10.height = 3263
	waypoint11.height = 3162
	
	assert_equal route.waypoints.length, 11
	route.waypoints.each do |waypoint|
	  assert !waypoint.invalid?
	end
    assert_difference('Route.count') do
      post :create, :route => {:name => 'North Twin Ascent', :type => 'Route', :name_status => 'Official', :travel_time => 'Unknown', :insert_id => users(:vador).id, :place_id => places(:north_twin).id, :distance => 26.47, :height_gain => 1942, :height_loss => 238, :waypoints_attributes => {"0" => waypoint1.attributes, "1" => waypoint2.attributes, "2" => waypoint3.attributes, "3" => waypoint4.attributes, "4" => waypoint5.attributes, "5" => waypoint6.attributes, "6" => waypoint7.attributes, "7" => waypoint8.attributes, "8" => waypoint9.attributes, "9" => waypoint10.attributes, "10" => waypoint11.attributes}}
    end

    assert_redirected_to route_path(assigns(:route))
    #Must change height of waypoint 6 to equal summit of North Twin.
#assert_equal places(:north_twin).latitude.to_f, assigns(:route).waypoints[6].latitude.to_f
#assert_equal places(:north_twin).longitude.to_f, assigns(:route).waypoints[6].longitude.to_f
    assert_equal places(:north_twin).height.to_f, assigns(:route).waypoints[6].height.to_f
    #Must link to North Twin and West Stutfield
    assert_equal 2, assigns(:route).places.count
    assert !assigns(:route).places.find(places(:north_twin).id).nil?
    assert !assigns(:route).places.find(places(:stutfield).id).nil?
    sign_out @admin
  end

  #This insert of Pauls crashed.
  test "should create route with trip" do
    sign_in @admin
    assert_difference('Route.count') do
      post :create, :route=>{"name"=>"Howe Sound Crest (South)", :place_id => places(:north_twin).id, "waypoints_attributes"=>{"22"=>{"location"=>"", "latitude"=>"49.471185960172896", "id"=>"", "_destroy"=>"false", "height"=>"345", "description"=>"", "local_index"=>"22", "longitude"=>"-123.2314710403291", "difficulty"=>"", "parent_index"=>"21"}, "11"=>{"location"=>"", "latitude"=>"49.45899752178748", "id"=>"", "_destroy"=>"false", "height"=>"723", "description"=>"", "local_index"=>"11", "longitude"=>"-123.21293161161816", "difficulty"=>"", "parent_index"=>"10"}, "6"=>{"location"=>"", "latitude"=>"49.45746329298053", "id"=>"", "_destroy"=>"false", "height"=>"971", "description"=>"", "local_index"=>"6", "longitude"=>"-123.2017736221162", "difficulty"=>"", "parent_index"=>"5"}, "23"=>{"location"=>"", "latitude"=>"49.47285919324728", "id"=>"", "_destroy"=>"false", "height"=>"251", "description"=>"", "local_index"=>"23", "longitude"=>"-123.23421762236035", "difficulty"=>"", "parent_index"=>"22"}, "12"=>{"location"=>"", "latitude"=>"49.46008540038294", "id"=>"", "_destroy"=>"false", "height"=>"722", "description"=>"", "local_index"=>"12", "longitude"=>"-123.21413324125683", "difficulty"=>"", "parent_index"=>"11"}, "7"=>{"location"=>"", "latitude"=>"49.45852331073934", "id"=>"", "_destroy"=>"false", "height"=>"868", "description"=>"", "local_index"=>"7", "longitude"=>"-123.2031039977876", "difficulty"=>"", "parent_index"=>"6"}, "24"=>{"location"=>"", "latitude"=>"49.47054453900673", "id"=>"", "_destroy"=>"false", "height"=>"225", "description"=>"", "local_index"=>"24", "longitude"=>"-123.23481843717968", "difficulty"=>"", "parent_index"=>"23"}, "13"=>{"location"=>"", "latitude"=>"49.46256790468718", "id"=>"", "_destroy"=>"false", "height"=>"662", "description"=>"", "local_index"=>"13", "longitude"=>"-123.21915433653271", "difficulty"=>"", "parent_index"=>"12"}, "8"=>{"location"=>"", "latitude"=>"49.45997382420252", "id"=>"", "_destroy"=>"false", "height"=>"808", "description"=>"", "local_index"=>"8", "longitude"=>"-123.20452020414745", "difficulty"=>"", "parent_index"=>"7"}, "14"=>{"location"=>"", "latitude"=>"49.46145218797566", "id"=>"", "_destroy"=>"true", "height"=>"496", "description"=>"", "local_index"=>"14", "longitude"=>"-123.2225017333833", "difficulty"=>"", "parent_index"=>"13"}, "9"=>{"location"=>"", "latitude"=>"49.45997382420252", "id"=>"", "_destroy"=>"false", "height"=>"795", "description"=>"", "local_index"=>"9", "longitude"=>"-123.20576474913036", "difficulty"=>"", "parent_index"=>"8"}, "15"=>{"location"=>"", "latitude"=>"49.46008540038294", "id"=>"", "_destroy"=>"true", "height"=>"352", "description"=>"", "local_index"=>"15", "longitude"=>"-123.22546289213574", "difficulty"=>"", "parent_index"=>"14"}, "16"=>{"location"=>"", "latitude"=>"49.45961119986175", "id"=>"", "_destroy"=>"true", "height"=>"200", "description"=>"", "local_index"=>"16", "longitude"=>"-123.23009774931347", "difficulty"=>"", "parent_index"=>"15"}, "0"=>{"location"=>"", "latitude"=>"49.39013314030055", "id"=>"", "_destroy"=>"false", "height"=>"949", "description"=>"", "local_index"=>"0", "longitude"=>"-123.18701074369824", "difficulty"=>"", "parent_index"=>"-1"}, "17"=>{"location"=>"", "latitude"=>"49.46371148795189", "id"=>"", "_destroy"=>"false", "height"=>"633", "description"=>"", "local_index"=>"17", "longitude"=>"-123.22052762754833", "difficulty"=>"", "parent_index"=>"13"}, "1"=>{"location"=>"", "latitude"=>"49.40666717284191", "id"=>"", "_destroy"=>"false", "height"=>"1228", "description"=>"", "local_index"=>"1", "longitude"=>"-123.20211694487011", "difficulty"=>"", "parent_index"=>"0"}, "18"=>{"location"=>"", "latitude"=>"49.465161847847355", "id"=>"", "_destroy"=>"false", "height"=>"647", "description"=>"", "local_index"=>"18", "longitude"=>"-123.22439000852978", "difficulty"=>"", "parent_index"=>"17"}, "2"=>{"location"=>"", "latitude"=>"49.42810843425663", "id"=>"", "_destroy"=>"false", "height"=>"1327", "description"=>"", "local_index"=>"2", "longitude"=>"-123.20486352690136", "difficulty"=>"", "parent_index"=>"1"}, "20"=>{"location"=>"", "latitude"=>"49.47241300334938", "id"=>"", "_destroy"=>"false", "height"=>"523", "description"=>"", "local_index"=>"20", "longitude"=>"-123.22666452177441", "difficulty"=>"", "parent_index"=>"19"}, "19"=>{"location"=>"", "latitude"=>"49.46909433845385", "id"=>"", "_destroy"=>"false", "height"=>"626", "description"=>"", "local_index"=>"19", "longitude"=>"-123.2254199767915", "difficulty"=>"", "parent_index"=>"18"}, "3"=>{"location"=>"", "latitude"=>"49.44373678231067", "id"=>"", "_destroy"=>"false", "height"=>"1406", "description"=>"", "local_index"=>"3", "longitude"=>"-123.19799707182324", "difficulty"=>"", "parent_index"=>"2"}, "21"=>{"location"=>"", "latitude"=>"49.47235722932635", "id"=>"", "_destroy"=>"false", "height"=>"419", "description"=>"", "local_index"=>"21", "longitude"=>"-123.230011918625", "difficulty"=>"", "parent_index"=>"20"}, "10"=>{"location"=>"", "latitude"=>"49.45866278505336", "id"=>"", "_destroy"=>"false", "height"=>"740", "description"=>"", "local_index"=>"10", "longitude"=>"-123.20829675444042", "difficulty"=>"", "parent_index"=>"9"}, "4"=>{"location"=>"", "latitude"=>"49.451772279393545", "id"=>"", "_destroy"=>"false", "height"=>"1361", "description"=>"", "local_index"=>"4", "longitude"=>"-123.18975732572949", "difficulty"=>"", "parent_index"=>"3"}, "5"=>{"location"=>"", "latitude"=>"49.45623587535282", "id"=>"", "_destroy"=>"false", "height"=>"1284", "description"=>"", "local_index"=>"5", "longitude"=>"-123.19404886015331", "difficulty"=>"", "parent_index"=>"4"}}, "alternate_names"=>"", "type"=>"Route", "equipment"=>"skis", "description"=>"", "name_status"=>"Official", "trip_reports_attributes"=>{"0"=>{"end_time"=>"2010-12-28 16:00", "participants"=>"max, stoked", "title"=>"Howe Sound Crest (South) ski traverse", "abstract"=>"A traverse of Howe Sound Crest from Cypress Mountain ski area to Lions Bay village.", "description"=>"a", "start_time"=>"2010-12-28 08:00"}}}, :place_id => places(:north_twin).id  
    end
    
    assert_redirected_to trip_report_path(assigns(:route).trip_reports.first)
    sign_out @admin
  end
 
  #This insert of Dieters crashed.
  test "shouldn't create road" do
    sign_in @admin
    post :create, :route=>{"name"=>"", :place_id => places(:north_twin).id, "waypoints_attributes"=>{"11"=>{"location"=>"", "latitude"=>"53.19851228525483", "id"=>"", "_destroy"=>"true", "height"=>"1099", "description"=>"", "local_index"=>7, "longitude"=>"-117.91037173705297", "difficulty"=>"", "parent_index"=>6}, "6"=>{"location"=>"", "latitude"=>"53.20321662698958", "id"=>"", "_destroy"=>"false", "height"=>"1040", "description"=>"", "local_index"=>3, "longitude"=>"-117.92367549376684", "difficulty"=>"", "parent_index"=>2}, "12"=>{"location"=>"Campground", "latitude"=>"53.19858940977406", "id"=>"", "_destroy"=>"false", "height"=>"1098", "description"=>"winding", "local_index"=>7, "longitude"=>"-117.91045756774145", "difficulty"=>"", "parent_index"=>6}, "7"=>{"location"=>"", "latitude"=>"53.19915498534155", "id"=>"", "_destroy"=>"false", "height"=>"1053", "description"=>"", "local_index"=>4, "longitude"=>"-117.92234511809545", "difficulty"=>"", "parent_index"=>3}, "13"=>{"location"=>"", "latitude"=>"53.193935982068936", "id"=>"", "_destroy"=>"false", "height"=>"1150", "description"=>"", "local_index"=>8, "longitude"=>"-117.90384860472875", "difficulty"=>"", "parent_index"=>7}, "8"=>{"location"=>"", "latitude"=>"53.1992321087044", "id"=>"", "_destroy"=>"true", "height"=>"1075", "description"=>"", "local_index"=>5, "longitude"=>"-117.91964145140844", "difficulty"=>"", "parent_index"=>4}, "14"=>{"location"=>"", "latitude"=>"53.19637845186118", "id"=>"", "_destroy"=>"true", "height"=>"1137", "description"=>"", "local_index"=>9, "longitude"=>"-117.90384860472875", "difficulty"=>"", "parent_index"=>8}, "9"=>{"location"=>"Punchbowl Falls", "latitude"=>"53.19936064733408", "id"=>"", "_destroy"=>"false", "height"=>"1076", "description"=>"flat and winding", "local_index"=>5, "longitude"=>"-117.91972728209691", "difficulty"=>"", "parent_index"=>4}, "15"=>{"location"=>"Lookout over Fiddle river and Ashlar Ridge", "latitude"=>"53.19637845186118", "id"=>"", "_destroy"=>"false", "height"=>"1138", "description"=>"winding", "local_index"=>9, "longitude"=>"-117.90380568938451", "difficulty"=>"", "parent_index"=>8}, "16"=>{"location"=>"", "latitude"=>"53.18249308669017", "id"=>"", "_destroy"=>"false", "height"=>"1322", "description"=>"", "local_index"=>10, "longitude"=>"-117.87807794051366", "difficulty"=>"", "parent_index"=>9}, "0"=>{"location"=>"Junction with the Yellowhead Highway", "latitude"=>"53.205015965445064", "id"=>"", "_destroy"=>"false", "height"=>"1040", "description"=>"Uphill with a few minor switchbacks", "local_index"=>0, "longitude"=>"-117.92831035094457", "difficulty"=>"", "parent_index"=>-1}, "17"=>{"location"=>"", "latitude"=>"53.17572877125037", "id"=>"", "_destroy"=>"false", "height"=>"1198", "description"=>"", "local_index"=>11, "longitude"=>"-117.84014077620702", "difficulty"=>"", "parent_index"=>10}, "1"=>{"location"=>"Pullout for trailhead to the old Pocahantas townsite", "latitude"=>"53.20331944836502", "id"=>"", "_destroy"=>"true", "height"=>"1040", "description"=>"uphill with minor switchbacks\r\n", "local_index"=>1, "longitude"=>"-117.92642207579809", "difficulty"=>"", "parent_index"=>0}, "18"=>{"location"=>"", "latitude"=>"53.178095116968635", "id"=>"", "_destroy"=>"false", "height"=>"1160", "description"=>"", "local_index"=>12, "longitude"=>"-117.83503385024267", "difficulty"=>"", "parent_index"=>11}, "2"=>{"location"=>"", "latitude"=>"53.20434764855195", "id"=>"", "_destroy"=>"true", "height"=>"1040", "description"=>"", "local_index"=>1, "longitude"=>"-117.92264552550512", "difficulty"=>"", "parent_index"=>1}, "20"=>{"location"=>"", "latitude"=>"53.15162061923012", "id"=>"", "_destroy"=>"false", "height"=>"1240", "description"=>"", "local_index"=>14, "longitude"=>"-117.78894277053075", "difficulty"=>"", "parent_index"=>13}, "19"=>{"location"=>"", "latitude"=>"53.159881180253876", "id"=>"", "_destroy"=>"false", "height"=>"1217", "description"=>"", "local_index"=>13, "longitude"=>"-117.81113000350194", "difficulty"=>"", "parent_index"=>12}, "3"=>{"location"=>"", "latitude"=>"53.20416771529994", "id"=>"", "_destroy"=>"true", "height"=>"1040", "description"=>"", "local_index"=>1, "longitude"=>"-117.92676539855199", "difficulty"=>"", "parent_index"=>0}, "21"=>{"location"=>"Miette Hotsprings. Trailhead for the Sulphur Skyline, Mystery Lake and Fiddle Pass trails", "latitude"=>"53.13548092005866", "id"=>"", "_destroy"=>"false", "height"=>"1360", "description"=>"end of road", "local_index"=>15, "longitude"=>"-117.77280660109716", "difficulty"=>"", "parent_index"=>14}, "10"=>{"location"=>"", "latitude"=>"53.19959201589617", "id"=>"", "_destroy"=>"false", "height"=>"1090", "description"=>"", "local_index"=>6, "longitude"=>"-117.91286082701879", "difficulty"=>"", "parent_index"=>5}, "4"=>{"location"=>"Pullout for trailhead to the old Pocahantas townsite", "latitude"=>"53.204219124877596", "id"=>"", "_destroy"=>"false", "height"=>"1040", "description"=>"uphill", "local_index"=>1, "longitude"=>"-117.92689414458471", "difficulty"=>"", "parent_index"=>0}, "5"=>{"location"=>"", "latitude"=>"53.20486173939485", "id"=>"", "_destroy"=>"false", "height"=>"1040", "description"=>"", "local_index"=>2, "longitude"=>"-117.92200179534154", "difficulty"=>"", "parent_index"=>1}}, "alternate_names"=>"", "type"=>"Road", "equipment"=>"", "description"=>"", "name_status"=>"Official"}, :place_id => places(:one).id
    assert_equal 3, Route.count

    sign_out @admin
  end

#  test "Should make route an ascent route" do
#    sign_in @admin
#    assert_difference('Route.count') do
#      post :create, :route=>{"name"=>"Brew Lake trail", "waypoints_attributes"=>{"0"=>{"location"=>"", "latitude"=>"50.041226592172165", "id"=>"", "_destroy"=>"false", "height"=>"568", "description"=>"", "local_index"=>"0", "longitude"=>"-123.1344226821289", "difficulty"=>"", "parent_index"=>"-1"}, "1"=>{"location"=>"", "latitude"=>"50.04387245104704", "id"=>"", "_destroy"=>"false", "height"=>"584", "description"=>"", "local_index"=>"1", "longitude"=>"-123.14120330651855", "difficulty"=>"", "parent_index"=>"0"}, "2"=>{"location"=>"", "latitude"=>"50.030145474166076", "id"=>"", "_destroy"=>"false", "height"=>"723", "description"=>"", "local_index"=>"2", "longitude"=>"-123.14639606317138", "difficulty"=>"", "parent_index"=>"1"}, "3"=>{"location"=>"", "latitude"=>"50.04246685667782", "id"=>"", "_destroy"=>"false", "height"=>"1671", "description"=>"", "local_index"=>"3", "longitude"=>"-123.19119968255614", "difficulty"=>"", "parent_index"=>"2"}}, "alternate_names"=>"", "type"=>"Route", "equipment"=>"Backcountry skis, ski crampons.", "description"=>"", "name_status"=>"Unofficial", "trip_reports_attributes"=>{"0"=>{"end_time"=>"2011-02-06 17:00", "participants"=>"stoked, max", "title"=>"Mount Brew ski, summer trail", "abstract"=>"", "description"=>"a", "start_time"=>"2011-02-06 09:00"}}}
#    end

#    assert_redirected_to trip_report_path(assigns(:route).trip_reports.first)
#   assert_equal places(:brew).latitude.to_f, assigns(:route).waypoints[1].latitude.to_f
#   assert_equal places(:brew).longitude.to_f, assigns(:route).waypoints[1].longitude.to_f
#   assert_equal places(:brew).height.to_f, assigns(:route).waypoints[1].height.to_f
#    assert_equal places(:brew).id, assigns(:route).place_id
#    assert_equal "Scramble", assigns(:route).type
#    sign_out @admin
#  end

  test "should show route" do
    sign_in @admin
    get :show, :id => routes(:columbia).to_param
    assert_response :success
    sign_out @admin
  end

  test "should get edit" do
    sign_in @editor
    get :edit, :id => routes(:columbia).to_param
    assert_response :success
    sign_out @editor
  end

  test "should update route" do
    sign_in @admin
    route = routes(:columbia)
    put :update, :id => route.to_param, :route => {:name => route.name, :type => 'Scramble', :name_status => 'Official', :travel_time => 'Unknown', :insert_id => users(:vador).id, :place_id => places(:columbia).id, :waypoints_attributes => {"0" => route.waypoints[0].attributes, "1" => route.waypoints[1].attributes, "2" => route.waypoints[2].attributes}}
    assert_redirected_to route_path(assigns(:route))
    sign_out @admin
  end

#  test "should destroy route" do
#    sign_in @admin
#    assert_difference('Route.count', -1) do
#      delete :destroy, :id => routes(:one).to_param
#    end

#    assert_redirected_to routes_path(:type => 'Trail')
#    sign_out @admin
#  end
end
