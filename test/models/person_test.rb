require "test_helper"

class PersonTest < ActiveSupport::TestCase
  def setup
    @image_io = StringIO.new(
      [
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
        0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196,
        137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 248, 255, 255, 63,
        0, 5, 254, 2, 254, 167, 53, 129, 132, 0, 0, 0, 0, 73, 69, 78,
        68, 174, 66, 96, 130
      ].pack("C*")
    )
  end

  test "has_photo? returns false when no photo attached or file_name set" do
    person = Person.new
    assert_not person.has_photo?
  end

  test "has_photo? returns true when legacy photo_file_name is set" do
    person = Person.new(photo_file_name: "guide.jpg")
    assert person.has_photo?
  end

  test "has_photo? returns true when ActiveStorage photo is attached" do
    person = Person.new
    person.photo.attach(io: StringIO.new(@image_io.string), filename: "guide.png", content_type: "image/png")
    assert person.has_photo?
  end

  test "validates content type on photo attachment" do
    person = Person.new(name: "Test Guide")
    person.photo.attach(io: StringIO.new("not an image"), filename: "test.txt", content_type: "text/plain")
    assert_not person.valid?
    assert_includes person.errors[:photo], "must be a JPEG, PNG, or GIF"
  end

  test "validates max file size on photo attachment" do
    person = Person.new(name: "Test Guide")
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake large image"),
      filename: "large.jpg",
      content_type: "image/jpeg"
    )
    blob.update_column(:byte_size, 6.megabytes)
    person.photo.attach(blob)
    assert_not person.valid?
    assert_includes person.errors[:photo], "must be less than 5MB"
  end

  test "syncs attachment attributes on validation" do
    person = Person.new(name: "Test Guide")
    person.photo.attach(io: StringIO.new(@image_io.string), filename: "guide.png", content_type: "image/png")
    assert person.valid?

    person.sync_attachment_attributes
    assert_equal "guide.png", person.photo_file_name
    assert_equal "image/png", person.photo_content_type
    assert_equal @image_io.string.bytesize, person.photo_file_size
    assert_not_nil person.photo_updated_at
  end

  test "named variants medium and thumb are configured" do
    person = Person.new
    person.photo.attach(io: StringIO.new(@image_io.string), filename: "guide.png", content_type: "image/png")

    assert person.photo.variant(:medium)
    assert person.photo.variant(:thumb)
  end
end
