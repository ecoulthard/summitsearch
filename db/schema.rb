# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_09_25_050015) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "albums", id: :serial, force: :cascade do |t|
    t.string "title", limit: 128
    t.text "description"
    t.timestamptz "time"
    t.integer "user_id"
    t.integer "feature_id"
    t.integer "route_id"
    t.integer "area_id"
    t.decimal "ref_latitude", precision: 8, scale: 6, null: false
    t.decimal "ref_longitude", precision: 9, scale: 6, null: false
    t.string "ref_title", limit: 30, null: false
    t.text "ref_content", null: false
    t.integer "photo_id"
    t.integer "update_id"
    t.decimal "importance", precision: 6, scale: 2
    t.boolean "deleted"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "topic_id"
    t.timestamptz "last_liked_at"
    t.timestamptz "last_comment_at"
    t.integer "total_comments"
    t.integer "total_likes"
    t.integer "place_id"
    t.index ["created_at"], name: "index_albums_on_created_at"
    t.index ["importance"], name: "index_albums_on_importance"
    t.index ["place_id"], name: "index_albums_on_place_id"
    t.index ["topic_id"], name: "index_albums_on_topic_id"
    t.index ["user_id"], name: "index_albums_on_user_id"
  end

  create_table "area_album_in_areas", id: :serial, force: :cascade do |t|
    t.integer "area_id", null: false
    t.integer "album_id", null: false
    t.index ["album_id"], name: "index_area_album_in_areas_on_album_id"
    t.index ["area_id"], name: "index_area_album_in_areas_on_area_id"
  end

  create_table "area_albums", id: :serial, force: :cascade do |t|
    t.integer "area_id", null: false
    t.integer "album_id", null: false
    t.boolean "in_title", default: false
    t.index ["album_id"], name: "index_area_albums_on_album_id"
    t.index ["area_id"], name: "index_area_albums_on_area_id"
  end

  create_table "area_areas", id: :serial, force: :cascade do |t|
    t.integer "parent_area_id", null: false
    t.integer "child_area_id", null: false
    t.index ["child_area_id"], name: "index_area_areas_on_child_area_id"
    t.index ["parent_area_id"], name: "index_area_areas_on_parent_area_id"
  end

  create_table "area_features", id: :serial, force: :cascade do |t|
    t.integer "area_id", null: false
    t.integer "feature_id", null: false
    t.index ["area_id"], name: "index_area_features_on_area_id"
    t.index ["feature_id"], name: "index_area_features_on_feature_id"
  end

  create_table "area_photo_in_areas", id: :serial, force: :cascade do |t|
    t.integer "area_id"
    t.integer "photo_id"
    t.index ["area_id"], name: "index_area_photo_in_areas_on_area_id"
    t.index ["photo_id"], name: "index_area_photo_in_areas_on_photo_id"
  end

  create_table "area_photos", id: :serial, force: :cascade do |t|
    t.integer "area_id", null: false
    t.integer "photo_id", null: false
    t.boolean "in_title", default: false
    t.index ["area_id"], name: "index_area_photos_on_area_id"
    t.index ["photo_id"], name: "index_area_photos_on_photo_id"
  end

  create_table "area_places", id: :serial, force: :cascade do |t|
    t.integer "area_id", null: false
    t.integer "place_id", null: false
    t.index ["area_id"], name: "index_area_places_on_area_id"
    t.index ["place_id"], name: "index_area_places_on_place_id"
  end

  create_table "area_routes", id: :serial, force: :cascade do |t|
    t.integer "area_id"
    t.integer "route_id"
    t.index ["area_id"], name: "index_area_routes_on_area_id"
    t.index ["route_id"], name: "index_area_routes_on_route_id"
  end

  create_table "areas", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255, null: false
    t.string "name", limit: 64, null: false
    t.string "alternate_names", limit: 128
    t.string "name_status", limit: 32, default: "Official", null: false
    t.text "match_names"
    t.text "reject_names"
    t.text "description"
    t.text "references"
    t.integer "area"
    t.integer "min_height"
    t.integer "max_height"
    t.decimal "max_latitude", precision: 8, scale: 6, null: false
    t.decimal "min_latitude", precision: 8, scale: 6, null: false
    t.decimal "max_longitude", precision: 9, scale: 6, null: false
    t.decimal "min_longitude", precision: 9, scale: 6, null: false
    t.integer "parent_area_id"
    t.boolean "partial_name_match", null: false
    t.integer "insert_id", null: false
    t.integer "update_id"
    t.decimal "importance", precision: 19, scale: 10
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "ref_area_id"
    t.integer "ref_feature_id"
    t.integer "forum_id"
    t.string "slug", limit: 255
    t.boolean "sub_region", default: false
    t.index ["forum_id"], name: "index_areas_on_forum_id"
    t.index ["importance"], name: "index_areas_on_importance"
    t.index ["insert_id"], name: "index_areas_on_insert_id"
    t.index ["slug"], name: "index_areas_on_slug", unique: true
    t.index ["type", "created_at"], name: "index_areas_on_type_and_created_at"
    t.index ["type"], name: "index_areas_on_type"
  end

  create_table "ascent_people", id: :serial, force: :cascade do |t|
    t.integer "ascent_id", null: false
    t.integer "person_id", null: false
    t.index ["ascent_id"], name: "index_ascent_people_on_ascent_id"
    t.index ["person_id"], name: "index_ascent_people_on_person_id"
  end

  create_table "ascents", id: :serial, force: :cascade do |t|
    t.integer "feature_id"
    t.integer "route_id"
    t.integer "ascent_index"
    t.boolean "solo", default: false, null: false
    t.boolean "success", default: true, null: false
    t.boolean "other_participants", default: false, null: false
    t.text "description"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.integer "year", limit: 2
    t.integer "month"
    t.integer "day"
    t.integer "winter_ascent_index"
    t.integer "route_ascent_index"
    t.integer "place_id"
    t.index ["feature_id"], name: "index_ascents_on_feature_id"
    t.index ["place_id"], name: "index_ascents_on_place_id"
    t.index ["route_id"], name: "index_ascents_on_route_id"
  end

  create_table "border_points", id: :serial, force: :cascade do |t|
    t.decimal "latitude", precision: 8, scale: 6, null: false
    t.decimal "longitude", precision: 9, scale: 6, null: false
    t.integer "place_id", null: false
    t.integer "local_index", null: false
    t.index ["place_id"], name: "index_border_points_on_place_id"
  end

  create_table "boundary_points", id: :serial, force: :cascade do |t|
    t.decimal "latitude", precision: 8, scale: 6, null: false
    t.decimal "longitude", precision: 9, scale: 6, null: false
    t.integer "area_id", null: false
    t.integer "local_index", null: false
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["area_id"], name: "index_boundary_points_on_area_id"
  end

  create_table "feature_albums", id: :serial, force: :cascade do |t|
    t.integer "feature_id", null: false
    t.integer "album_id", null: false
    t.boolean "in_title", default: false
    t.index ["album_id"], name: "index_feature_albums_on_album_id"
    t.index ["feature_id"], name: "index_feature_albums_on_feature_id"
  end

  create_table "feature_photos", id: :serial, force: :cascade do |t|
    t.integer "feature_id", null: false
    t.integer "photo_id", null: false
    t.boolean "in_title", default: false
    t.index ["feature_id"], name: "index_feature_photos_on_feature_id"
    t.index ["photo_id"], name: "index_feature_photos_on_photo_id"
  end

  create_table "feature_routes", id: :serial, force: :cascade do |t|
    t.integer "feature_id"
    t.integer "route_id"
    t.integer "waypoint_index"
    t.index ["feature_id"], name: "index_feature_routes_on_feature_id"
    t.index ["route_id"], name: "index_feature_routes_on_route_id"
  end

  create_table "features", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255, null: false
    t.string "name", limit: 32, null: false
    t.string "name_status", limit: 32, default: "Official", null: false
    t.string "alternate_names", limit: 128
    t.string "province", limit: 64
    t.text "match_names"
    t.text "reject_names"
    t.integer "height", null: false
    t.decimal "latitude", precision: 8, scale: 6, null: false
    t.decimal "longitude", precision: 9, scale: 6, null: false
    t.text "description"
    t.text "history"
    t.text "references"
    t.integer "parent_mountain_id"
    t.integer "dist_to_parent"
    t.boolean "partial_name_match", null: false
    t.integer "insert_id", null: false
    t.integer "update_id"
    t.integer "bivouac_id"
    t.integer "height_error"
    t.decimal "importance", precision: 19, scale: 10
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "ref_feature_id"
    t.integer "ref_area_id"
    t.decimal "computed_value1", precision: 10
    t.decimal "computed_value2", precision: 10
    t.integer "nearby_namesake_id"
    t.string "slug", limit: 255
    t.integer "name_reference"
    t.integer "height_reference"
    t.index ["computed_value1"], name: "index_features_on_computed_value1"
    t.index ["computed_value2"], name: "index_features_on_computed_value2"
    t.index ["dist_to_parent"], name: "index_features_on_dist_to_parent"
    t.index ["height"], name: "index_features_on_height"
    t.index ["importance"], name: "index_features_on_importance"
    t.index ["insert_id"], name: "index_features_on_insert_id"
    t.index ["slug"], name: "index_features_on_slug", unique: true
    t.index ["type", "created_at"], name: "index_features_on_type_and_created_at"
    t.index ["type"], name: "index_features_on_type"
  end

  create_table "forem_categories", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "slug", limit: 255
    t.integer "position", default: 0
    t.index ["slug"], name: "index_forem_categories_on_slug", unique: true
  end

  create_table "forem_forums", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.integer "category_id"
    t.integer "views_count", default: 0
    t.string "slug", limit: 255
    t.integer "position", default: 0
    t.index ["slug"], name: "index_forem_forums_on_slug", unique: true
  end

  create_table "forem_groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.index ["name"], name: "index_forem_groups_on_name"
  end

  create_table "forem_memberships", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "member_id"
    t.index ["group_id"], name: "index_forem_memberships_on_group_id"
  end

  create_table "forem_moderator_groups", id: :serial, force: :cascade do |t|
    t.integer "forum_id"
    t.integer "group_id"
    t.index ["forum_id"], name: "index_forem_moderator_groups_on_forum_id"
  end

  create_table "forem_posts", id: :serial, force: :cascade do |t|
    t.integer "topic_id"
    t.text "text"
    t.integer "user_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "reply_to_id"
    t.string "state", limit: 255, default: "pending_review"
    t.boolean "notified", default: false
    t.index ["reply_to_id"], name: "index_forem_posts_on_reply_to_id"
    t.index ["state"], name: "index_forem_posts_on_state"
    t.index ["topic_id"], name: "index_forem_posts_on_topic_id"
    t.index ["user_id"], name: "index_forem_posts_on_user_id"
  end

  create_table "forem_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "subscriber_id"
    t.integer "topic_id"
  end

  create_table "forem_topics", id: :serial, force: :cascade do |t|
    t.integer "forum_id"
    t.integer "user_id"
    t.string "subject", limit: 255
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.boolean "locked", default: false, null: false
    t.boolean "pinned", default: false
    t.boolean "hidden", default: false
    t.string "state", limit: 255, default: "pending_review"
    t.timestamptz "last_post_at"
    t.integer "views_count", default: 0
    t.integer "feature_id"
    t.integer "area_id"
    t.integer "album_id"
    t.integer "photo_id"
    t.integer "trip_report_id"
    t.string "slug", limit: 255
    t.integer "place_id"
    t.index ["album_id"], name: "index_forem_topics_on_album_id"
    t.index ["area_id"], name: "index_forem_topics_on_area_id"
    t.index ["feature_id"], name: "index_forem_topics_on_feature_id"
    t.index ["forum_id"], name: "index_forem_topics_on_forum_id"
    t.index ["photo_id"], name: "index_forem_topics_on_photo_id"
    t.index ["slug"], name: "index_forem_topics_on_slug", unique: true
    t.index ["state"], name: "index_forem_topics_on_state"
    t.index ["trip_report_id"], name: "index_forem_topics_on_trip_report_id"
    t.index ["user_id"], name: "index_forem_topics_on_user_id"
  end

  create_table "forem_views", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "viewable_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.integer "count", default: 0
    t.string "viewable_type", limit: 255
    t.timestamptz "current_viewed_at"
    t.timestamptz "past_viewed_at"
    t.index ["updated_at"], name: "index_forem_views_on_updated_at"
    t.index ["user_id"], name: "index_forem_views_on_user_id"
    t.index ["viewable_id"], name: "index_forem_views_on_viewable_id"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", limit: 255, null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 40
    t.timestamptz "created_at"
    t.string "scope", limit: 255
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "ip_addresses", id: :serial, force: :cascade do |t|
    t.string "address", limit: 255, null: false
    t.integer "user_id"
    t.integer "visit_count", null: false
    t.timestamptz "first_visit_at", null: false
    t.timestamptz "last_visit_at", null: false
    t.string "last_http_user_agent", limit: 255, null: false
    t.string "city", limit: 255
    t.boolean "human"
    t.timestamptz "forem_last_visit_at"
    t.timestamptz "forem_first_visit_at"
    t.index ["address"], name: "index_ip_addresses_on_address"
  end

  create_table "mountain_details", id: :serial, force: :cascade do |t|
    t.integer "mountain_id"
    t.integer "parent_mountain_id"
    t.decimal "dist_to_parent", precision: 19, scale: 10
    t.decimal "height_and_isolation", precision: 28, scale: 10
    t.integer "prominence"
    t.decimal "average_slope", precision: 28, scale: 10
    t.decimal "steepest_slope", precision: 28, scale: 10
    t.decimal "border_latitude_steepest_slope", precision: 8, scale: 6
    t.decimal "border_longitude_steepest_slope", precision: 9, scale: 6
  end

  create_table "names", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.integer "person_id"
    t.string "named_by_other", limit: 255
    t.integer "feature_id"
    t.integer "area_id"
    t.integer "route_id"
    t.integer "year"
    t.text "description"
    t.integer "named_after_person_id"
    t.integer "place_id"
    t.index ["area_id"], name: "index_names_on_area_id"
    t.index ["feature_id"], name: "index_names_on_feature_id"
    t.index ["named_after_person_id"], name: "index_names_on_named_after_person_id"
    t.index ["person_id"], name: "index_names_on_person_id"
    t.index ["place_id"], name: "index_names_on_place_id"
    t.index ["route_id"], name: "index_names_on_route_id"
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.string "name", limit: 128, null: false
    t.string "photo_file_name", limit: 255
    t.string "photo_content_type", limit: 255
    t.integer "photo_file_size"
    t.timestamptz "photo_updated_at"
    t.string "photo_caption", limit: 255
    t.text "description"
    t.text "references"
    t.timestamptz "birthdate"
    t.timestamptz "deathdate"
    t.string "slug", limit: 255
    t.integer "importance"
    t.integer "insert_id", null: false
    t.integer "update_id"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.boolean "guide", default: false
    t.index ["importance"], name: "index_people_on_importance"
    t.index ["insert_id"], name: "index_people_on_insert_id"
    t.index ["slug"], name: "index_people_on_slug", unique: true
    t.index ["update_id"], name: "index_people_on_update_id"
  end

  create_table "photos", id: :serial, force: :cascade do |t|
    t.string "title", limit: 128
    t.timestamptz "time"
    t.integer "feature_id"
    t.integer "trip_report_id"
    t.integer "area_id"
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.text "vantage"
    t.text "caption"
    t.text "description"
    t.integer "user_id"
    t.integer "height"
    t.decimal "ref_latitude", precision: 8, scale: 6
    t.decimal "ref_longitude", precision: 9, scale: 6
    t.string "ref_title", limit: 128
    t.string "ref_content", limit: 1024
    t.integer "update_id"
    t.decimal "importance", precision: 19, scale: 10
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "photo_file_name", limit: 255
    t.string "photo_content_type", limit: 255
    t.integer "photo_file_size"
    t.timestamptz "photo_updated_at"
    t.integer "route_id"
    t.integer "album_id"
    t.integer "topic_id"
    t.timestamptz "last_liked_at"
    t.timestamptz "last_comment_at"
    t.integer "total_comments"
    t.integer "total_likes"
    t.integer "photo_width"
    t.integer "photo_height"
    t.integer "place_id"
    t.index ["album_id"], name: "index_photos_on_album_id"
    t.index ["area_id"], name: "index_photos_on_area_id"
    t.index ["created_at"], name: "index_photos_on_created_at"
    t.index ["feature_id"], name: "index_photos_on_feature_id"
    t.index ["importance"], name: "index_photos_on_importance"
    t.index ["place_id"], name: "index_photos_on_place_id"
    t.index ["route_id"], name: "index_photos_on_route_id"
    t.index ["topic_id"], name: "index_photos_on_topic_id"
    t.index ["trip_report_id"], name: "index_photos_on_trip_report_id"
    t.index ["user_id"], name: "index_photos_on_user_id"
  end

  create_table "place_album_in_areas", id: :serial, force: :cascade do |t|
    t.integer "place_id", null: false
    t.integer "album_id", null: false
    t.index ["album_id"], name: "index_place_album_in_areas_on_album_id"
    t.index ["place_id"], name: "index_place_album_in_areas_on_place_id"
  end

  create_table "place_albums", id: :serial, force: :cascade do |t|
    t.integer "place_id", null: false
    t.integer "album_id", null: false
    t.boolean "in_title", default: false
    t.index ["album_id"], name: "index_place_albums_on_album_id"
    t.index ["place_id"], name: "index_place_albums_on_place_id"
  end

  create_table "place_photo_in_areas", id: :serial, force: :cascade do |t|
    t.integer "place_id"
    t.integer "photo_id"
    t.index ["photo_id"], name: "index_place_photo_in_areas_on_photo_id"
    t.index ["place_id"], name: "index_place_photo_in_areas_on_place_id"
  end

  create_table "place_photos", id: :serial, force: :cascade do |t|
    t.integer "place_id"
    t.integer "photo_id"
    t.boolean "in_title", default: false
    t.index ["photo_id"], name: "index_place_photos_on_photo_id"
    t.index ["place_id"], name: "index_place_photos_on_place_id"
  end

  create_table "place_route_in_areas", id: :serial, force: :cascade do |t|
    t.integer "place_id"
    t.integer "route_id"
    t.index ["place_id"], name: "index_place_route_in_areas_on_place_id"
    t.index ["route_id"], name: "index_place_route_in_areas_on_route_id"
  end

  create_table "place_routes", id: :serial, force: :cascade do |t|
    t.integer "place_id"
    t.integer "route_id"
    t.integer "waypoint_index"
    t.index ["place_id"], name: "index_place_routes_on_place_id"
    t.index ["route_id"], name: "index_place_routes_on_route_id"
  end

  create_table "places", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255, null: false
    t.string "name", limit: 64, null: false
    t.string "name_status", limit: 32, default: "Official", null: false
    t.integer "name_reference", limit: 2
    t.integer "int", limit: 2
    t.string "alternate_names", limit: 128
    t.string "slug", limit: 255
    t.string "province", limit: 64
    t.boolean "partial_name_match", null: false
    t.text "match_names"
    t.text "reject_names"
    t.integer "nearby_namesake_id"
    t.integer "height"
    t.integer "height_reference", limit: 2
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.integer "area"
    t.decimal "max_latitude", precision: 8, scale: 6
    t.decimal "min_latitude", precision: 8, scale: 6
    t.decimal "max_longitude", precision: 9, scale: 6
    t.decimal "min_longitude", precision: 9, scale: 6
    t.integer "parent_area_id"
    t.integer "forum_id"
    t.boolean "sub_region", default: false
    t.text "description"
    t.text "references"
    t.integer "ref_place_id"
    t.decimal "importance", precision: 28, scale: 10
    t.integer "insert_id", null: false
    t.integer "update_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "feature_id"
    t.integer "area_id"
    t.index ["area_id"], name: "index_places_on_area_id"
    t.index ["feature_id"], name: "index_places_on_feature_id"
    t.index ["slug"], name: "index_places_on_slug", unique: true
  end

  create_table "route_albums", id: :serial, force: :cascade do |t|
    t.integer "route_id", null: false
    t.integer "album_id", null: false
    t.boolean "in_title", default: false
    t.index ["album_id"], name: "index_route_albums_on_album_id"
    t.index ["route_id"], name: "index_route_albums_on_route_id"
  end

  create_table "route_photos", id: :serial, force: :cascade do |t|
    t.integer "route_id", null: false
    t.integer "photo_id", null: false
    t.boolean "in_title", default: false
    t.index ["photo_id"], name: "index_route_photos_on_photo_id"
    t.index ["route_id"], name: "index_route_photos_on_route_id"
  end

  create_table "routes", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255, null: false
    t.string "name", limit: 128, null: false
    t.string "alternate_names", limit: 128
    t.string "name_status", limit: 32, default: "Official", null: false
    t.text "equipment"
    t.text "description"
    t.text "references"
    t.string "travel_time", limit: 255, null: false
    t.integer "difficulty"
    t.decimal "distance", precision: 5, scale: 2
    t.integer "height_gain"
    t.integer "height_loss"
    t.integer "feature_id"
    t.boolean "partial_name_match"
    t.integer "insert_id", null: false
    t.integer "update_id"
    t.decimal "importance", precision: 19, scale: 10
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "match_names"
    t.text "reject_names"
    t.string "gps_file_name", limit: 255
    t.string "gps_content_type", limit: 255
    t.integer "gps_file_size"
    t.timestamptz "gps_updated_at"
    t.integer "road_id"
    t.integer "descent_route_id"
    t.text "access"
    t.boolean "different_start_end", default: false, null: false
    t.boolean "newb", default: false, null: false
    t.string "avalanche_rating", limit: 255
    t.boolean "glacier_travel", default: false, null: false
    t.text "objective_hazard"
    t.boolean "seracs", default: false, null: false
    t.boolean "rockfall", default: false, null: false
    t.boolean "river_crossing", default: false, null: false
    t.integer "place_id"
    t.index ["importance"], name: "index_routes_on_importance"
    t.index ["insert_id"], name: "index_routes_on_insert_id"
    t.index ["place_id"], name: "index_routes_on_place_id"
    t.index ["type", "created_at"], name: "index_routes_on_type_and_created_at"
    t.index ["type", "feature_id"], name: "index_routes_on_type_and_feature_id"
  end

  create_table "trip_reports", id: :serial, force: :cascade do |t|
    t.string "title", limit: 128
    t.timestamptz "start_time"
    t.timestamptz "end_time"
    t.text "abstract"
    t.text "participants", null: false
    t.text "description"
    t.integer "route_id", null: false
    t.integer "user_id", null: false
    t.integer "update_id"
    t.decimal "importance", precision: 19, scale: 10
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "travel_time", limit: 255
    t.integer "topic_id"
    t.timestamptz "last_liked_at"
    t.timestamptz "last_comment_at"
    t.integer "total_comments"
    t.integer "total_likes"
    t.string "type", limit: 255
    t.boolean "snowshoeing"
    t.boolean "skiing"
    t.index ["created_at"], name: "index_trip_reports_on_created_at"
    t.index ["importance"], name: "index_trip_reports_on_importance"
    t.index ["route_id"], name: "index_trip_reports_on_route_id"
    t.index ["topic_id"], name: "index_trip_reports_on_topic_id"
    t.index ["user_id"], name: "index_trip_reports_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.string "password_salt", limit: 255, default: "", null: false
    t.string "confirmation_token", limit: 255
    t.timestamptz "confirmed_at"
    t.timestamptz "confirmation_sent_at"
    t.string "reset_password_token", limit: 255
    t.timestamptz "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.timestamptz "current_sign_in_at"
    t.timestamptz "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "realname", limit: 64, null: false
    t.integer "role_index", default: 2, null: false
    t.string "city", limit: 32, null: false
    t.string "province", limit: 32, null: false
    t.string "country", limit: 32, null: false
    t.timestamptz "content_contributer_until"
    t.timestamptz "paid_contributer_until"
    t.timestamptz "contributer_until"
    t.text "description"
    t.string "home_page", limit: 100
    t.integer "recentGrantedAccessTime", default: 0
    t.text "notifications"
    t.timestamptz "last_visit_at"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.string "photo_file_name", limit: 255
    t.string "photo_content_type", limit: 255
    t.integer "photo_file_size"
    t.timestamptz "photo_updated_at"
    t.text "photo_caption"
    t.string "last_http_user_agent", limit: 200
    t.string "username", limit: 64
    t.boolean "forem_admin", default: false
    t.timestamptz "reset_password_sent_at"
    t.string "forem_state", limit: 255, default: "approved"
    t.boolean "forem_auto_subscribe", default: true
    t.text "signature"
    t.timestamptz "forem_last_visit_at"
    t.timestamptz "forem_first_visit_at"
    t.string "slug", limit: 255
    t.timestamptz "last_photo_uploaded_at", default: "2013-02-06 08:48:16"
    t.string "unconfirmed_email", limit: 255
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "views", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "viewable_id"
    t.string "viewable_type", limit: 255
    t.integer "count"
    t.integer "rating"
    t.timestamptz "current_viewed_at"
    t.timestamptz "past_viewed_at"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["user_id"], name: "index_views_on_user_id"
    t.index ["viewable_id"], name: "index_views_on_viewable_id"
    t.index ["viewable_type"], name: "index_views_on_viewable_type"
  end

  create_table "visits", id: :serial, force: :cascade do |t|
    t.integer "ip_address_id", null: false
    t.integer "visitable_id", null: false
    t.string "visitable_type", limit: 255, null: false
    t.timestamptz "current_visited_at"
    t.timestamptz "datetime"
    t.timestamptz "past_visited_at"
    t.integer "count", default: 0
    t.boolean "facebook_like"
    t.boolean "google_plus"
    t.timestamptz "created_at", null: false
    t.timestamptz "updated_at", null: false
    t.index ["ip_address_id"], name: "index_visits_on_ip_address_id"
    t.index ["visitable_id"], name: "index_visits_on_visitable_id"
    t.index ["visitable_type"], name: "index_visits_on_visitable_type"
  end

  create_table "waypoints", id: :serial, force: :cascade do |t|
    t.decimal "latitude", precision: 8, scale: 6, null: false
    t.decimal "longitude", precision: 9, scale: 6, null: false
    t.integer "height"
    t.string "location", limit: 255
    t.string "difficulty", limit: 32
    t.text "description"
    t.integer "route_id", null: false
    t.integer "parent_index"
    t.integer "local_index", null: false
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.decimal "distance", precision: 5, scale: 2
    t.string "icon", limit: 32
    t.string "title", limit: 255
    t.integer "height_gain"
    t.integer "height_loss"
    t.index ["route_id"], name: "index_waypoints_on_route_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
