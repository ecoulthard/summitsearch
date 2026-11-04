class LegacyPhotoImagesController < ActionController::Base
  include PhotosHelper

  def show
    # Cached pages keep this application URL; only the redirect expires.
    response.headers["Cache-Control"] = "no-store"
    return head :not_found unless %w[original medium small thumb long_thumb tiny].include?(params[:style])

    photo = Photo.find_signed(params[:signed_id], purpose: :legacy_photo_image)
    return head :not_found unless photo&.photo_file_name.present?

    redirect_to legacy_s3_presigned_url(photo, params[:style]), allow_other_host: true
  end
end
