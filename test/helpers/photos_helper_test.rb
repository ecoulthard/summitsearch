require "test_helper"

class PhotosHelperTest < ActionView::TestCase
  test "photo_variant with nil photo returns nil" do
    assert_nil photo_variant(nil)
    assert_equal "", photo_variant_url(nil)
  end

  test "photo_image_tag with unattached photo without filename returns fallback" do
    photo = Photo.new
    result = photo_image_tag(photo, :thumb)
    assert_includes result, "No image"
  end

  test "photo_variant_url and photo_image_tag with legacy paperclip record" do
    photo = Photo.new(photo_file_name: "edith-cavell.jpg")
    photo.id = 1

    url = photo_variant_url(photo, :medium)
    assert_includes url, "photos/photos/1/medium/edith-cavell.jpg"

    result = photo_image_tag(photo, :medium, alt: "Edith Cavell")
    assert_includes result, "<img"
    assert_includes result, "photos/photos/1/medium/edith-cavell.jpg"
    assert_includes result, "Edith Cavell"
  end

  test "photo_variant_url with AWS credentials generates presigned url" do
    photo = Photo.new(photo_file_name: "edith-cavell.jpg")
    photo.id = 1

    ENV["AWS_ACCESS_KEY_ID"] = "test_key"
    ENV["AWS_SECRET_ACCESS_KEY"] = "test_secret"
    ENV["S3_BUCKET_NAME"] = "test-bucket"

    url = photo_variant_url(photo, :medium)
    assert_includes url, "test-bucket.s3"
    assert_includes url, "X-Amz-Signature"
  ensure
    ENV.delete("AWS_ACCESS_KEY_ID")
    ENV.delete("AWS_SECRET_ACCESS_KEY")
    ENV.delete("S3_BUCKET_NAME")
  end

  test "renders photos/thumb partial correctly" do
    photo = Photo.new(
      id: 1,
      title: "Mount Columbia",
      caption: "View from summit",
      photo_file_name: "columbia.jpg",
      photo_width: 1000,
      photo_height: 500
    )

    rendered = render(partial: "photos/thumb", locals: { photo: photo })
    assert_includes rendered, "thumbDiv"
    assert_includes rendered, "Mount Columbia"
    assert_includes rendered, "<img"
    assert_includes rendered, "photos/photos/1/long_thumb/columbia.jpg"
  end
end
