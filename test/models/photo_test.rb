require 'test_helper'

class PhotoTest < ActiveSupport::TestCase
  fixtures :photos
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  test "Photo attributes must not be empty" do
    photo = Photo.new
    assert photo.invalid?
    assert photo.errors[:user_id].any?
    assert photo.errors[:ref_latitude].any?
    assert photo.errors[:ref_longitude].any?
    assert photo.errors[:ref_title].any?
    assert photo.errors[:ref_content].any?
  end
  
  test "Find by time returns photos for the given user in the given time interval" do
    assert_equal photos(:columbia).id, Photo.find_by_time(Time.local(2009,"may",9,8,00,00), Time.local(2009,"may",11,17,00,00)).first.id
    assert_equal Photo.find_by_time(Time.utc(2009,"may",10,5,00,00), Time.utc(2009,"may",10,6,00,00)), []
    assert_equal photos(:columbia).id, Photo.find_by_time(photos(:columbia).time+30.minutes, photos(:columbia).time+1.hour).first.id
  end
  
  test "Finds and links parent place" do
    photo = Photo.find_by_title("Mount Columbia")
    photo.set_places(photo.title, photo.caption)
  end
  
  test "Find and link all mentioned places and parent trip report" do
    photo = Photo.find_by_title("View North West of Mount Columbia")
    photo.caption = photo.caption + ' ' #Need to change photo caption to get it to relink
    photo.set_links
    assert_equal 11, photo.places_mentioned.length
    assert !photo.places_mentioned.find_by_name("Wales Peak").nil?
    assert photo.places_mentioned.find_by_name("Chaba Peak") != []
    assert photo.places_mentioned.find_by_name("Mount Clemeneau") != []
    assert photo.places_mentioned.find_by_name("False Chaba Peak") != []
    assert photo.places_mentioned.find_by_name("Listening Mountain") != []
    assert photo.places_mentioned.find_by_name("Sundial Mountain") != []
    assert photo.places_mentioned.find_by_name("Sundial E4") != []
    assert photo.places_mentioned.find_by_name("Mount Hooker") != []
    assert photo.places_mentioned.find_by_name("Serenity Mountain") != []
    assert photo.places_mentioned.find_by_name("Warwick Mountain") != []
    assert photo.places_mentioned.find_by_name("Dais Mountain") != []
  end

  test "Finds and links parent trip report" do
    photo = Photo.find_by_title("Mount Columbia")
    photo.set_trip_report
    assert_equal TripReport.find_by_title("Success on Mount Columbia"), photo.trip_report
  end

 test "No duplicate photos" do
    columbia_photo = Photo.find_by_title("Mount Columbia")
    photo = Photo.new(:title => '',:caption => '',
		    :time => columbia_photo.time,
		    :photo_file_name => columbia_photo.photo_file_name,
		    :photo_content_type => columbia_photo.photo_content_type,
		    :photo_file_size => columbia_photo.photo_file_size,
		    :ref_latitude => columbia_photo.ref_latitude,
		    :ref_longitude => columbia_photo.ref_longitude,
		    :ref_title => columbia_photo.ref_title,
		    :ref_content => columbia_photo.ref_content,
		    :user_id => columbia_photo.user_id
		    )
    assert photo.invalid?
    assert photo.errors[:photo_file_name].any?
    photo.title = "Not Columbia"
    assert photo.valid?
  end
end
