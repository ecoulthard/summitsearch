class ForumPhotosController < ApplicationController
  skip_before_action :editor_required, :admin_required, raise: false
  before_action :photo_context

  rescue_from ForumPhotoAttachments::NotAllowed do |error|
    render json: { error: error.message }, status: :forbidden
  end
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Discussion or place not found" }, status: :not_found
  end
  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def index
    photos = ForumPhotoAttachments.eligible(current_user, @topic)
    if params[:search].present?
      search = "%#{Photo.sanitize_sql_like(params[:search].to_s)}%"
      photos = photos.where("title ILIKE :query OR caption ILIKE :query", query: search)
    end
    page = [ params[:page].to_i, 1 ].max
    photos = photos.order(created_at: :desc, id: :desc).offset((page - 1) * 20).limit(21).to_a
    render json: { photos: photos.first(20).map { |photo| photo_data(photo) }, more: photos.size > 20 }
  end

  def places
    places = Place.none
    if params[:search].to_s.strip.length >= 2
      places = Place.where("name ILIKE ?", "%#{Place.sanitize_sql_like(params[:search].to_s.strip)}%")
        .order(:name, :id).limit(20)
    end
    render json: places.map { |place| { id: place.id, name: place.name } }
  end

  def create
    place = Place.find(params[:place_id])
    unless place.centerLatitude && place.centerLongitude
      return render json: { error: "Choose a place with coordinates" }, status: :unprocessable_entity
    end
    unless params[:file].is_a?(ActionDispatch::Http::UploadedFile)
      return render json: { error: "Choose a JPEG, PNG, or GIF" }, status: :unprocessable_entity
    end

    photo = Photo.create!(user: current_user, photo: params[:file], title: params[:title].to_s.truncate(128).presence,
      ref_title: place.name.to_s.truncate(128), ref_content: "Uploaded for a forum discussion",
      ref_latitude: place.centerLatitude, ref_longitude: place.centerLongitude)
    current_user.update_columns(last_photo_uploaded_at: Time.current)
    render json: photo_data(photo), status: :created
  end

  private

  def photo_context
    raise ForumPhotoAttachments::NotAllowed, "Sign in to add photos" unless current_user

    if params[:topic_id].present?
      @topic = Thredded::Topic.find(params[:topic_id])
      ForumPhotoAttachments.authorize!(current_user, @topic)
    else
      board = Thredded::Messageboard.find(params[:messageboard_id])
      policy = Thredded::MessageboardPolicy.new(current_user, board)
      raise ForumPhotoAttachments::NotAllowed, "Photos cannot be added to this board" unless policy.read? && policy.post?
    end
  end

  def photo_data(photo)
    { id: photo.id, title: photo.title.presence || "Photo #{photo.id}",
      thumbnail: helpers.photo_variant_url(photo, :thumb) }
  end
end
