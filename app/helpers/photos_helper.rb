module PhotosHelper
  # Returns the ActiveStorage variant or attachment for a photo record.
  def photo_variant(photo, style = nil)
    return nil unless photo&.photo&.attached?
    style.present? ? photo.photo.variant(style) : photo.photo
  end

  # Returns the URL for an attached photo, falling back to legacy Paperclip path or S3 URL.
  def photo_variant_url(photo, style = :medium)
    return "" unless photo

    if photo.photo.attached?
      variant = photo_variant(photo, style)
      variant ? url_for(variant) : ""
    elsif photo.respond_to?(:photo_file_name) && photo.photo_file_name.present? && photo.id.present?
      style_name = style.presence || :medium
      local_rel_path = "/system/photos/photos/#{photo.id}/#{style_name}/#{photo.photo_file_name}"
      if Rails.root.join("public", local_rel_path.delete_prefix("/")).exist?
        local_rel_path
      elsif ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?
        legacy_s3_presigned_url(photo, style_name)
      else
        bucket = ENV["S3_BUCKET_NAME"].presence || "summitsearch"
        "https://#{bucket}.s3.amazonaws.com/photos/photos/#{photo.id}/#{style_name}/#{photo.photo_file_name}"
      end
    else
      ""
    end
  end

  # Renders an image tag for a photo with ActiveStorage variant or legacy Paperclip fallback.
  def photo_image_tag(photo, style = :long_thumb, **options)
    return content_tag(:div, "No image", class: "no-image") unless photo

    if photo.photo.attached?
      image_tag(photo_variant(photo, style), **options)
    elsif photo.respond_to?(:photo_file_name) && photo.photo_file_name.present?
      src = photo_variant_url(photo, style)
      src.present? ? image_tag(src, **options) : content_tag(:div, "No image", class: "no-image")
    else
      content_tag(:div, "No image", class: "no-image")
    end
  end

  private

  def s3_presigner
    @s3_presigner ||= begin
      require "aws-sdk-s3"
      client = Aws::S3::Client.new(
        region: ENV.fetch("AWS_REGION", "us-east-1"),
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
      )
      Aws::S3::Presigner.new(client: client)
    end
  end

  def legacy_s3_presigned_url(photo, style_name)
    bucket = ENV["S3_BUCKET_NAME"].presence || "summitsearch"
    key = "photos/photos/#{photo.id}/#{style_name}/#{photo.photo_file_name}"
    s3_presigner.presigned_url(:get_object, bucket: bucket, key: key, expires_in: 3600)
  rescue StandardError => e
    Rails.logger.warn("Failed to generate presigned S3 URL for photo #{photo.id}: #{e.message}")
    bucket = ENV["S3_BUCKET_NAME"].presence || "summitsearch"
    "https://#{bucket}.s3.amazonaws.com/#{key}"
  end
end
