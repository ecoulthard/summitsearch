require "test_helper"

class UserTest < ActiveSupport::TestCase
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
    user = User.new
    assert_not user.has_photo?
  end

  test "has_photo? returns true when legacy photo_file_name is set" do
    user = User.new(photo_file_name: "avatar.jpg")
    assert user.has_photo?
  end

  test "has_photo? returns true when ActiveStorage photo is attached" do
    user = User.new
    user.photo.attach(io: StringIO.new(@image_io.string), filename: "avatar.png", content_type: "image/png")
    assert user.has_photo?
  end

  test "validates content type on photo attachment" do
    user = User.new(realname: "Test User", email: "test@example.com", password: "password123", city: "Calgary", province: "AB", country: "Canada")
    user.photo.attach(io: StringIO.new("not an image"), filename: "test.txt", content_type: "text/plain")
    assert_not user.valid?
    assert_includes user.errors[:photo], "must be a JPEG or PNG"
  end

  test "validates max file size on photo attachment" do
    user = User.new(realname: "Test User", email: "test@example.com", password: "password123", city: "Calgary", province: "AB", country: "Canada")
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake large image"),
      filename: "large.jpg",
      content_type: "image/jpeg"
    )
    blob.update_column(:byte_size, 6.megabytes)
    user.photo.attach(blob)
    assert_not user.valid?
    assert_includes user.errors[:photo], "must be less than 5MB"
  end

  test "syncs attachment attributes on validation" do
    user = User.new(realname: "Test User", email: "test@example.com", password: "password123", city: "Calgary", province: "AB", country: "Canada")
    user.photo.attach(io: StringIO.new(@image_io.string), filename: "profile.png", content_type: "image/png")
    assert user.valid?, user.errors.full_messages.to_sentence

    user.sync_attachment_attributes
    assert_equal "profile.png", user.photo_file_name
    assert_equal "image/png", user.photo_content_type
    assert_equal @image_io.string.bytesize, user.photo_file_size
    assert_not_nil user.photo_updated_at
  end

  test "named variants medium and thumb are configured" do
    user = User.new
    user.photo.attach(io: StringIO.new(@image_io.string), filename: "profile.png", content_type: "image/png")

    assert user.photo.variant(:medium)
    assert user.photo.variant(:thumb)
  end

  test "cannot delete last admin" do
    admin = users(:vador)
    assert admin.valid?
    assert_raises(RuntimeError) do
      admin.destroy
    end
  end
end
