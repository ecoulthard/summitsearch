require "test_helper"

class LegacyPhotoImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_aws_env = ENV.to_h.slice("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "S3_BUCKET_NAME")
    ENV.update("AWS_ACCESS_KEY_ID" => "test_key", "AWS_SECRET_ACCESS_KEY" => "test_secret", "S3_BUCKET_NAME" => "test-bucket")
    @photo = photos(:one)
    @path = legacy_photo_image_path(signed_id: @photo.signed_id(purpose: :legacy_photo_image), style: :long_thumb)
  end

  teardown do
    %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY S3_BUCKET_NAME].each { |key| ENV.delete(key) }
    ENV.update(@original_aws_env)
  end

  test "cached image URL generates a fresh redirect after the S3 signature expires" do
    get @path
    assert_response :redirect
    assert_equal "no-store", response.headers["Cache-Control"]
    first_location = response.location
    assert_includes first_location, "photos/photos/#{@photo.id}/long_thumb/#{@photo.photo_file_name}"
    assert_includes first_location, "X-Amz-Signature"

    travel 3.hours do
      get @path
      assert_response :redirect
      refute_equal first_location, response.location
    end
  end

  test "rejects invalid signatures and unsupported styles" do
    get legacy_photo_image_path(signed_id: "invalid", style: :thumb)
    assert_response :not_found
    get legacy_photo_image_path(signed_id: @photo.signed_id(purpose: :legacy_photo_image), style: :unsupported)
    assert_response :not_found
  end
end
