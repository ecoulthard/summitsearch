require "test_helper"
require "minitest/mock"

class PhotoTest < ActiveSupport::TestCase
  def setup
    # Create a 100x50 sample PNG image
    # Minimal 1x1 PNG or mini_magick generated image
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

  test "validates presence of photo attachment" do
    photo = Photo.new(user_id: 1, title: "Test Photo")
    assert_not photo.valid?
    assert_includes photo.errors[:photo], "can't be blank"
  end

  test "validates presence of user_id" do
    photo = Photo.new(title: "Test Photo")
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "test.png", content_type: "image/png")
    assert_not photo.valid?
    assert_includes photo.errors[:user_id], "can't be blank"
  end

  test "validates content type" do
    photo = Photo.new(user_id: 1, title: "Invalid File")
    photo.photo.attach(io: StringIO.new("plain text content"), filename: "test.txt", content_type: "text/plain")
    assert_not photo.valid?
    assert_includes photo.errors[:photo], "must be a JPEG, PNG, or GIF"
  end

  test "validates max file size" do
    photo = Photo.new(user_id: 1, title: "Large File")
    # Attach a blob that reports > 50 MB
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake large image"),
      filename: "large.jpg",
      content_type: "image/jpeg"
    )
    blob.update_column(:byte_size, 51.megabytes)
    photo.photo.attach(blob)
    assert_not photo.valid?
    assert_includes photo.errors[:photo], "must be less than 50MB"
  end

  test "successful attachment and sync of attachment attributes" do
    photo = Photo.new(user_id: 1, title: "Valid Photo")
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "summit.png", content_type: "image/png")
    assert photo.valid?

    photo.sync_attachment_attributes
    assert_equal "summit.png", photo.photo_file_name
    assert_equal "image/png", photo.photo_content_type
    assert_equal @image_io.string.bytesize, photo.photo_file_size
  end

  test "is_panorama? returns true for aspect ratio greater than 2.0" do
    photo = Photo.new(user_id: 1, photo_width: 3000, photo_height: 1000)
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "pano.png", content_type: "image/png")
    assert photo.is_panorama?

    photo.photo_width = 1000
    photo.photo_height = 1000
    assert_not photo.is_panorama?
  end

  test "is_panorama? returns false if photo is not attached" do
    photo = Photo.new(user_id: 1, photo_width: 3000, photo_height: 1000)
    assert_not photo.is_panorama?
  end

  test "dimension calculations for long thumb and small thumb" do
    photo = Photo.new(user_id: 1, photo_width: 1000, photo_height: 500)
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "test.png", content_type: "image/png")

    assert_equal 500, photo.max_long_thumb_width
    assert_equal 100, photo.max_long_thumb_height
    assert_equal 5, photo.max_long_thumb_ratio

    assert_equal 800, photo.max_small_width
    assert_equal 300, photo.max_small_height
    assert_equal 2, photo.max_small_ratio

    assert photo.long_thumb_width > 0
    assert photo.long_thumb_height > 0
    assert photo.small_width > 0
    assert photo.small_height > 0
  end

  test "named variants are defined on photo attachment" do
    photo = Photo.new(user_id: 1)
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "test.png", content_type: "image/png")

    assert photo.photo.variant(:thumb)
    assert photo.photo.variant(:medium)
    assert photo.photo.variant(:small)
    assert photo.photo.variant(:long_thumb)
    assert photo.photo.variant(:tiny)
    assert photo.photo.variant(:original)
  end

  test "setFieldsIfBlank sets width and height from blob metadata or mini_magick" do
    photo = Photo.new(user_id: 1, title: "Photo Without Dimensions")
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "test.png", content_type: "image/png")
    photo.sync_attachment_attributes

    assert_nil photo.photo_width
    assert_nil photo.photo_height

    photo.setFieldsIfBlank

    assert_equal 1, photo.photo_width
    assert_equal 1, photo.photo_height
  end

  test "setFieldsIfBlank copies GPS coordinates from neighbour photo when coordinates are blank" do
    neighbour = Photo.new(
      user_id: 1,
      title: "Neighbour Photo",
      latitude: 51.1784,
      longitude: -115.5708,
      height: 2400
    )

    photo = Photo.new(user_id: 1, title: "Current Photo")
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "test.png", content_type: "image/png")

    photo.stub :neighbourPhoto, neighbour do
      photo.setFieldsIfBlank
      assert_equal 51.1784, photo.latitude
      assert_equal -115.5708, photo.longitude
      assert_equal 2400, photo.height
    end
  end

  test "validates length of title, caption, vantage, description" do
    photo = Photo.new(user_id: 1, title: "a" * 129)
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "test.png", content_type: "image/png")
    assert_not photo.valid?
    assert_includes photo.errors[:title], "is too long (maximum is 128 characters)"

    photo = Photo.new(user_id: 1, caption: "a" * 30721)
    photo.photo.attach(io: StringIO.new(@image_io.string), filename: "test.png", content_type: "image/png")
    assert_not photo.valid?
    assert_includes photo.errors[:caption], "is too long (maximum is 30720 characters)"
  end

  test "setFieldsIfBlank parses EXIF metadata when available" do
    jpeg_bytes = [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48,
      0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08,
      0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20,
      0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27,
      0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
      0xBF, 0x00, 0xFF, 0xD9
    ].pack("C*")

    photo = Photo.new(user_id: 1, title: "EXIF Photo")
    photo.photo.attach(io: StringIO.new(jpeg_bytes), filename: "test.jpg", content_type: "image/jpeg")

    fake_exif = Struct.new(:width, :height, :date_time_original, :gps_latitude, :gps_latitude_ref, :gps_longitude, :gps_longitude_ref, :gps_altitude).new(
      4000,
      3000,
      Time.utc(2025, 8, 15, 14, 30, 0),
      [51.0, 10.0, 42.24],
      "N",
      [115.0, 34.0, 14.88],
      "W",
      2850.0
    )

    EXIFR::JPEG.stub :new, fake_exif do
      photo.setFieldsIfBlank
      assert_equal 4000, photo.photo_width
      assert_equal 3000, photo.photo_height
      assert_equal Time.utc(2025, 8, 15, 14, 30, 0), photo.time
      assert_in_delta 51.1784, photo.latitude, 0.0001
      assert_in_delta(-115.5708, photo.longitude, 0.0001)
      assert_equal 2850.0, photo.height
    end
  end

  test "no duplicate photos validation" do
    existing_photo = Photo.new(
      user_id: 1,
      title: "Same Title",
      time: Time.utc(2026, 1, 1, 12, 0, 0),
      photo_file_name: "dup.png",
      photo_file_size: @image_io.string.bytesize
    )

    photo2 = Photo.new(user_id: 1, title: "Same Title", time: Time.utc(2026, 1, 1, 12, 0, 0))
    photo2.photo.attach(io: StringIO.new(@image_io.string), filename: "dup.png", content_type: "image/png")
    photo2.sync_attachment_attributes

    Photo.stub :where, [existing_photo] do
      assert_not photo2.valid?
      assert_includes photo2.errors[:photo_file_name], "There is already a photo submitted by you with the same filename and time. To submit the same photo twice you need to at least give it a unique filename."
    end
  end
end
