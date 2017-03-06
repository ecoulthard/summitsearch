require 'test_helper'

class AlbumTest < ActiveSupport::TestCase
  fixtures :albums

  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "Finds and links parent place" do
    album = albums(:columbia)
    album.set_places(album.title, album.description)
  end
  
  test "Find and link all mentioned places" do
    album = albums(:columbia)
    album.set_links
    assert_equal 11, album.places_mentioned.length
    assert !album.places_mentioned.find_by_name("Wales Peak").nil?
    assert album.places_mentioned.find_by_name("Chaba Peak") != []
    assert album.places_mentioned.find_by_name("Mount Clemeneau") != []
    assert album.places_mentioned.find_by_name("False Chaba Peak") != []
    assert album.places_mentioned.find_by_name("Listening Mountain") != []
    assert album.places_mentioned.find_by_name("Sundial Mountain") != []
    assert album.places_mentioned.find_by_name("Sundial E4") != []
    assert album.places_mentioned.find_by_name("Mount Hooker") != []
    assert album.places_mentioned.find_by_name("Serenity Mountain") != []
    assert album.places_mentioned.find_by_name("Warwick Mountain") != []
    assert album.places_mentioned.find_by_name("Dais Mountain") != []
  end
end

