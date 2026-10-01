require "test_helper"

class AlbumTest < ActiveSupport::TestCase
  fixtures :albums, :places, :photos, :users

  test "Finds and links parent place" do
    album = albums(:columbia)
    album.set_places(album.title, album.description)
    assert_not_nil album.places
  end
  
  test "Find and link all mentioned places" do
    album = albums(:columbia)
    album.set_links
    assert_equal 11, album.places_mentioned.length
    assert_not_nil album.places_mentioned.find_by(name: "Wales Peak")
    assert_not_empty album.places_mentioned.where(name: "Chaba Peak")
    assert_not_nil album.places_mentioned.find_by(name: "Mount Clemenceau")
    assert_not_empty album.places_mentioned.where(name: "False Chaba Peak")
    assert_not_empty album.places_mentioned.where(name: "Listening Mountain")
    assert_not_empty album.places_mentioned.where(name: "Sundial Mountain")
    assert_not_empty album.places_mentioned.where(name: "Sundial E4")
    assert_not_empty album.places_mentioned.where(name: "Mount Hooker")
    assert_not_empty album.places_mentioned.where(name: "Serenity Mountain")
    assert_not_empty album.places_mentioned.where(name: "Warwick Mountain")
    assert_not_empty album.places_mentioned.where(name: "Dais Mountain")
  end
end
