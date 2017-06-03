# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170603183410) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "albums", force: true do |t|
    t.string   "title",           limit: 128
    t.text     "description"
    t.datetime "time"
    t.integer  "user_id"
    t.integer  "feature_id"
    t.integer  "route_id"
    t.integer  "area_id"
    t.decimal  "ref_latitude",                precision: 8, scale: 6, null: false
    t.decimal  "ref_longitude",               precision: 9, scale: 6, null: false
    t.string   "ref_title",       limit: 30,                          null: false
    t.text     "ref_content",                                         null: false
    t.integer  "photo_id"
    t.integer  "update_id"
    t.decimal  "importance",                  precision: 6, scale: 2
    t.boolean  "deleted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "topic_id"
    t.datetime "last_liked_at"
    t.datetime "last_comment_at"
    t.integer  "total_comments"
    t.integer  "total_likes"
    t.integer  "place_id"
  end

  add_index "albums", ["created_at"], name: "index_albums_on_created_at", using: :btree
  add_index "albums", ["importance"], name: "index_albums_on_importance", using: :btree
  add_index "albums", ["place_id"], name: "index_albums_on_place_id", using: :btree
  add_index "albums", ["topic_id"], name: "index_albums_on_topic_id", using: :btree
  add_index "albums", ["user_id"], name: "index_albums_on_user_id", using: :btree

  create_table "area_album_in_areas", force: true do |t|
    t.integer "area_id",  null: false
    t.integer "album_id", null: false
  end

  add_index "area_album_in_areas", ["album_id"], name: "index_area_album_in_areas_on_album_id", using: :btree
  add_index "area_album_in_areas", ["area_id"], name: "index_area_album_in_areas_on_area_id", using: :btree

  create_table "area_albums", force: true do |t|
    t.integer "area_id",                  null: false
    t.integer "album_id",                 null: false
    t.boolean "in_title", default: false
  end

  add_index "area_albums", ["album_id"], name: "index_area_albums_on_album_id", using: :btree
  add_index "area_albums", ["area_id"], name: "index_area_albums_on_area_id", using: :btree

  create_table "area_areas", force: true do |t|
    t.integer "parent_area_id", null: false
    t.integer "child_area_id",  null: false
  end

  add_index "area_areas", ["child_area_id"], name: "index_area_areas_on_child_area_id", using: :btree
  add_index "area_areas", ["parent_area_id"], name: "index_area_areas_on_parent_area_id", using: :btree

  create_table "area_features", force: true do |t|
    t.integer "area_id",    null: false
    t.integer "feature_id", null: false
  end

  add_index "area_features", ["area_id"], name: "index_area_features_on_area_id", using: :btree
  add_index "area_features", ["feature_id"], name: "index_area_features_on_feature_id", using: :btree

  create_table "area_photo_in_areas", force: true do |t|
    t.integer "area_id"
    t.integer "photo_id"
  end

  add_index "area_photo_in_areas", ["area_id"], name: "index_area_photo_in_areas_on_area_id", using: :btree
  add_index "area_photo_in_areas", ["photo_id"], name: "index_area_photo_in_areas_on_photo_id", using: :btree

  create_table "area_photos", force: true do |t|
    t.integer "area_id",                  null: false
    t.integer "photo_id",                 null: false
    t.boolean "in_title", default: false
  end

  add_index "area_photos", ["area_id"], name: "index_area_photos_on_area_id", using: :btree
  add_index "area_photos", ["photo_id"], name: "index_area_photos_on_photo_id", using: :btree

  create_table "area_places", force: true do |t|
    t.integer "area_id",  null: false
    t.integer "place_id", null: false
  end

  add_index "area_places", ["area_id"], name: "index_area_places_on_area_id", using: :btree
  add_index "area_places", ["place_id"], name: "index_area_places_on_place_id", using: :btree

  create_table "area_routes", force: true do |t|
    t.integer "area_id"
    t.integer "route_id"
  end

  add_index "area_routes", ["area_id"], name: "index_area_routes_on_area_id", using: :btree
  add_index "area_routes", ["route_id"], name: "index_area_routes_on_route_id", using: :btree

  create_table "areas", force: true do |t|
    t.string   "type",                                                                          null: false
    t.string   "name",               limit: 64,                                                 null: false
    t.string   "alternate_names",    limit: 128
    t.string   "name_status",        limit: 32,                            default: "Official", null: false
    t.text     "match_names"
    t.text     "reject_names"
    t.text     "description"
    t.text     "references"
    t.integer  "area"
    t.integer  "min_height"
    t.integer  "max_height"
    t.decimal  "max_latitude",                   precision: 8,  scale: 6,                       null: false
    t.decimal  "min_latitude",                   precision: 8,  scale: 6,                       null: false
    t.decimal  "max_longitude",                  precision: 9,  scale: 6,                       null: false
    t.decimal  "min_longitude",                  precision: 9,  scale: 6,                       null: false
    t.integer  "parent_area_id"
    t.boolean  "partial_name_match",                                                            null: false
    t.integer  "insert_id",                                                                     null: false
    t.integer  "update_id"
    t.decimal  "importance",                     precision: 19, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ref_area_id"
    t.integer  "ref_feature_id"
    t.integer  "forum_id"
    t.string   "slug"
    t.boolean  "sub_region",                                               default: false
  end

  add_index "areas", ["forum_id"], name: "index_areas_on_forum_id", using: :btree
  add_index "areas", ["importance"], name: "index_areas_on_importance", using: :btree
  add_index "areas", ["insert_id"], name: "index_areas_on_insert_id", using: :btree
  add_index "areas", ["slug"], name: "index_areas_on_slug", unique: true, using: :btree
  add_index "areas", ["type", "created_at"], name: "index_areas_on_type_and_created_at", using: :btree
  add_index "areas", ["type"], name: "index_areas_on_type", using: :btree

  create_table "ascent_people", force: true do |t|
    t.integer "ascent_id", null: false
    t.integer "person_id", null: false
  end

  add_index "ascent_people", ["ascent_id"], name: "index_ascent_people_on_ascent_id", using: :btree
  add_index "ascent_people", ["person_id"], name: "index_ascent_people_on_person_id", using: :btree

  create_table "ascents", force: true do |t|
    t.integer  "feature_id"
    t.integer  "route_id"
    t.integer  "ascent_index"
    t.boolean  "solo",                          default: false, null: false
    t.boolean  "success",                       default: true,  null: false
    t.boolean  "other_participants",            default: false, null: false
    t.text     "description"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "year",                limit: 2
    t.integer  "month"
    t.integer  "day"
    t.integer  "winter_ascent_index"
    t.integer  "route_ascent_index"
    t.integer  "place_id"
  end

  add_index "ascents", ["feature_id"], name: "index_ascents_on_feature_id", using: :btree
  add_index "ascents", ["place_id"], name: "index_ascents_on_place_id", using: :btree
  add_index "ascents", ["route_id"], name: "index_ascents_on_route_id", using: :btree

  create_table "border_points", force: true do |t|
    t.decimal "latitude",    precision: 8, scale: 6, null: false
    t.decimal "longitude",   precision: 9, scale: 6, null: false
    t.integer "place_id",                            null: false
    t.integer "local_index",                         null: false
  end

  add_index "border_points", ["place_id"], name: "index_border_points_on_place_id", using: :btree

  create_table "boundary_points", force: true do |t|
    t.decimal  "latitude",    precision: 8, scale: 6, null: false
    t.decimal  "longitude",   precision: 9, scale: 6, null: false
    t.integer  "area_id",                             null: false
    t.integer  "local_index",                         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "boundary_points", ["area_id"], name: "index_boundary_points_on_area_id", using: :btree

  create_table "feature_albums", force: true do |t|
    t.integer "feature_id",                 null: false
    t.integer "album_id",                   null: false
    t.boolean "in_title",   default: false
  end

  add_index "feature_albums", ["album_id"], name: "index_feature_albums_on_album_id", using: :btree
  add_index "feature_albums", ["feature_id"], name: "index_feature_albums_on_feature_id", using: :btree

  create_table "feature_photos", force: true do |t|
    t.integer "feature_id",                 null: false
    t.integer "photo_id",                   null: false
    t.boolean "in_title",   default: false
  end

  add_index "feature_photos", ["feature_id"], name: "index_feature_photos_on_feature_id", using: :btree
  add_index "feature_photos", ["photo_id"], name: "index_feature_photos_on_photo_id", using: :btree

  create_table "feature_routes", force: true do |t|
    t.integer "feature_id"
    t.integer "route_id"
    t.integer "waypoint_index"
  end

  add_index "feature_routes", ["feature_id"], name: "index_feature_routes_on_feature_id", using: :btree
  add_index "feature_routes", ["route_id"], name: "index_feature_routes_on_route_id", using: :btree

  create_table "features", force: true do |t|
    t.string   "type",                                                                          null: false
    t.string   "name",               limit: 32,                                                 null: false
    t.string   "name_status",        limit: 32,                            default: "Official", null: false
    t.string   "alternate_names",    limit: 128
    t.string   "province",           limit: 64
    t.text     "match_names"
    t.text     "reject_names"
    t.integer  "height",                                                                        null: false
    t.decimal  "latitude",                       precision: 8,  scale: 6,                       null: false
    t.decimal  "longitude",                      precision: 9,  scale: 6,                       null: false
    t.text     "description"
    t.text     "history"
    t.text     "references"
    t.integer  "parent_mountain_id"
    t.integer  "dist_to_parent"
    t.boolean  "partial_name_match",                                                            null: false
    t.integer  "insert_id",                                                                     null: false
    t.integer  "update_id"
    t.integer  "bivouac_id"
    t.integer  "height_error"
    t.decimal  "importance",                     precision: 19, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ref_feature_id"
    t.integer  "ref_area_id"
    t.decimal  "computed_value1",                precision: 10, scale: 0
    t.decimal  "computed_value2",                precision: 10, scale: 0
    t.integer  "nearby_namesake_id"
    t.string   "slug"
    t.integer  "name_reference"
    t.integer  "height_reference"
  end

  add_index "features", ["computed_value1"], name: "index_features_on_computed_value1", using: :btree
  add_index "features", ["computed_value2"], name: "index_features_on_computed_value2", using: :btree
  add_index "features", ["dist_to_parent"], name: "index_features_on_dist_to_parent", using: :btree
  add_index "features", ["height"], name: "index_features_on_height", using: :btree
  add_index "features", ["importance"], name: "index_features_on_importance", using: :btree
  add_index "features", ["insert_id"], name: "index_features_on_insert_id", using: :btree
  add_index "features", ["slug"], name: "index_features_on_slug", unique: true, using: :btree
  add_index "features", ["type", "created_at"], name: "index_features_on_type_and_created_at", using: :btree
  add_index "features", ["type"], name: "index_features_on_type", using: :btree

  create_table "forem_categories", force: true do |t|
    t.string   "name",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.integer  "position",   default: 0
  end

  add_index "forem_categories", ["slug"], name: "index_forem_categories_on_slug", unique: true, using: :btree

  create_table "forem_forums", force: true do |t|
    t.string  "name"
    t.text    "description"
    t.integer "category_id"
    t.integer "views_count", default: 0
    t.string  "slug"
    t.integer "position",    default: 0
  end

  add_index "forem_forums", ["slug"], name: "index_forem_forums_on_slug", unique: true, using: :btree

  create_table "forem_groups", force: true do |t|
    t.string "name"
  end

  add_index "forem_groups", ["name"], name: "index_forem_groups_on_name", using: :btree

  create_table "forem_memberships", force: true do |t|
    t.integer "group_id"
    t.integer "member_id"
  end

  add_index "forem_memberships", ["group_id"], name: "index_forem_memberships_on_group_id", using: :btree

  create_table "forem_moderator_groups", force: true do |t|
    t.integer "forum_id"
    t.integer "group_id"
  end

  add_index "forem_moderator_groups", ["forum_id"], name: "index_forem_moderator_groups_on_forum_id", using: :btree

  create_table "forem_posts", force: true do |t|
    t.integer  "topic_id"
    t.text     "text"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reply_to_id"
    t.string   "state",       default: "pending_review"
    t.boolean  "notified",    default: false
  end

  add_index "forem_posts", ["reply_to_id"], name: "index_forem_posts_on_reply_to_id", using: :btree
  add_index "forem_posts", ["state"], name: "index_forem_posts_on_state", using: :btree
  add_index "forem_posts", ["topic_id"], name: "index_forem_posts_on_topic_id", using: :btree
  add_index "forem_posts", ["user_id"], name: "index_forem_posts_on_user_id", using: :btree

  create_table "forem_subscriptions", force: true do |t|
    t.integer "subscriber_id"
    t.integer "topic_id"
  end

  create_table "forem_topics", force: true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "subject"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "locked",         default: false,            null: false
    t.boolean  "pinned",         default: false
    t.boolean  "hidden",         default: false
    t.string   "state",          default: "pending_review"
    t.datetime "last_post_at"
    t.integer  "views_count",    default: 0
    t.integer  "feature_id"
    t.integer  "area_id"
    t.integer  "album_id"
    t.integer  "photo_id"
    t.integer  "trip_report_id"
    t.string   "slug"
    t.integer  "place_id"
  end

  add_index "forem_topics", ["album_id"], name: "index_forem_topics_on_album_id", using: :btree
  add_index "forem_topics", ["area_id"], name: "index_forem_topics_on_area_id", using: :btree
  add_index "forem_topics", ["feature_id"], name: "index_forem_topics_on_feature_id", using: :btree
  add_index "forem_topics", ["forum_id"], name: "index_forem_topics_on_forum_id", using: :btree
  add_index "forem_topics", ["photo_id"], name: "index_forem_topics_on_photo_id", using: :btree
  add_index "forem_topics", ["slug"], name: "index_forem_topics_on_slug", unique: true, using: :btree
  add_index "forem_topics", ["state"], name: "index_forem_topics_on_state", using: :btree
  add_index "forem_topics", ["trip_report_id"], name: "index_forem_topics_on_trip_report_id", using: :btree
  add_index "forem_topics", ["user_id"], name: "index_forem_topics_on_user_id", using: :btree

  create_table "forem_views", force: true do |t|
    t.integer  "user_id"
    t.integer  "viewable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "count",             default: 0
    t.string   "viewable_type"
    t.datetime "current_viewed_at"
    t.datetime "past_viewed_at"
  end

  add_index "forem_views", ["updated_at"], name: "index_forem_views_on_updated_at", using: :btree
  add_index "forem_views", ["user_id"], name: "index_forem_views_on_user_id", using: :btree
  add_index "forem_views", ["viewable_id"], name: "index_forem_views_on_viewable_id", using: :btree

  create_table "friendly_id_slugs", force: true do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 40
    t.datetime "created_at"
    t.string   "scope"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "ip_addresses", force: true do |t|
    t.string   "address",              null: false
    t.integer  "user_id"
    t.integer  "visit_count",          null: false
    t.datetime "first_visit_at",       null: false
    t.datetime "last_visit_at",        null: false
    t.string   "last_http_user_agent", null: false
    t.string   "city"
    t.boolean  "human"
    t.datetime "forem_last_visit_at"
    t.datetime "forem_first_visit_at"
  end

  add_index "ip_addresses", ["address"], name: "index_ip_addresses_on_address", using: :btree

  create_table "mountain_details", force: true do |t|
    t.integer "mountain_id"
    t.integer "parent_mountain_id"
    t.decimal "dist_to_parent",                  precision: 19, scale: 10
    t.decimal "height_and_isolation",            precision: 28, scale: 10
    t.integer "prominence"
    t.decimal "average_slope",                   precision: 28, scale: 10
    t.decimal "steepest_slope",                  precision: 28, scale: 10
    t.decimal "border_latitude_steepest_slope",  precision: 8,  scale: 6
    t.decimal "border_longitude_steepest_slope", precision: 9,  scale: 6
  end

  create_table "names", force: true do |t|
    t.string  "name",                  null: false
    t.integer "person_id"
    t.string  "named_by_other"
    t.integer "feature_id"
    t.integer "area_id"
    t.integer "route_id"
    t.integer "year"
    t.text    "description"
    t.integer "named_after_person_id"
    t.integer "place_id"
  end

  add_index "names", ["area_id"], name: "index_names_on_area_id", using: :btree
  add_index "names", ["feature_id"], name: "index_names_on_feature_id", using: :btree
  add_index "names", ["named_after_person_id"], name: "index_names_on_named_after_person_id", using: :btree
  add_index "names", ["person_id"], name: "index_names_on_person_id", using: :btree
  add_index "names", ["place_id"], name: "index_names_on_place_id", using: :btree
  add_index "names", ["route_id"], name: "index_names_on_route_id", using: :btree

  create_table "people", force: true do |t|
    t.string   "name",               limit: 128,                 null: false
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "photo_caption"
    t.text     "description"
    t.text     "references"
    t.datetime "birthdate"
    t.datetime "deathdate"
    t.string   "slug"
    t.integer  "importance"
    t.integer  "insert_id",                                      null: false
    t.integer  "update_id"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.boolean  "guide",                          default: false
  end

  add_index "people", ["importance"], name: "index_people_on_importance", using: :btree
  add_index "people", ["insert_id"], name: "index_people_on_insert_id", using: :btree
  add_index "people", ["slug"], name: "index_people_on_slug", unique: true, using: :btree
  add_index "people", ["update_id"], name: "index_people_on_update_id", using: :btree

  create_table "photos", force: true do |t|
    t.string   "title",              limit: 128
    t.datetime "time"
    t.integer  "feature_id"
    t.integer  "trip_report_id"
    t.integer  "area_id"
    t.decimal  "latitude",                       precision: 8,  scale: 6
    t.decimal  "longitude",                      precision: 9,  scale: 6
    t.text     "vantage"
    t.text     "caption"
    t.text     "description"
    t.integer  "user_id"
    t.integer  "height"
    t.decimal  "ref_latitude",                   precision: 8,  scale: 6,  null: false
    t.decimal  "ref_longitude",                  precision: 9,  scale: 6,  null: false
    t.string   "ref_title",          limit: 128,                           null: false
    t.text     "ref_content",                                              null: false
    t.integer  "update_id"
    t.decimal  "importance",                     precision: 19, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "route_id"
    t.integer  "album_id"
    t.integer  "topic_id"
    t.datetime "last_liked_at"
    t.datetime "last_comment_at"
    t.integer  "total_comments"
    t.integer  "total_likes"
    t.integer  "photo_width"
    t.integer  "photo_height"
    t.integer  "place_id"
  end

  add_index "photos", ["album_id"], name: "index_photos_on_album_id", using: :btree
  add_index "photos", ["area_id"], name: "index_photos_on_area_id", using: :btree
  add_index "photos", ["created_at"], name: "index_photos_on_created_at", using: :btree
  add_index "photos", ["feature_id"], name: "index_photos_on_feature_id", using: :btree
  add_index "photos", ["importance"], name: "index_photos_on_importance", using: :btree
  add_index "photos", ["place_id"], name: "index_photos_on_place_id", using: :btree
  add_index "photos", ["route_id"], name: "index_photos_on_route_id", using: :btree
  add_index "photos", ["topic_id"], name: "index_photos_on_topic_id", using: :btree
  add_index "photos", ["trip_report_id"], name: "index_photos_on_trip_report_id", using: :btree
  add_index "photos", ["user_id"], name: "index_photos_on_user_id", using: :btree

  create_table "place_album_in_areas", force: true do |t|
    t.integer "place_id", null: false
    t.integer "album_id", null: false
  end

  add_index "place_album_in_areas", ["album_id"], name: "index_place_album_in_areas_on_album_id", using: :btree
  add_index "place_album_in_areas", ["place_id"], name: "index_place_album_in_areas_on_place_id", using: :btree

  create_table "place_albums", force: true do |t|
    t.integer "place_id",                 null: false
    t.integer "album_id",                 null: false
    t.boolean "in_title", default: false
  end

  add_index "place_albums", ["album_id"], name: "index_place_albums_on_album_id", using: :btree
  add_index "place_albums", ["place_id"], name: "index_place_albums_on_place_id", using: :btree

  create_table "place_photo_in_areas", force: true do |t|
    t.integer "place_id"
    t.integer "photo_id"
  end

  add_index "place_photo_in_areas", ["photo_id"], name: "index_place_photo_in_areas_on_photo_id", using: :btree
  add_index "place_photo_in_areas", ["place_id"], name: "index_place_photo_in_areas_on_place_id", using: :btree

  create_table "place_photos", force: true do |t|
    t.integer "place_id"
    t.integer "photo_id"
    t.boolean "in_title", default: false
  end

  add_index "place_photos", ["photo_id"], name: "index_place_photos_on_photo_id", using: :btree
  add_index "place_photos", ["place_id"], name: "index_place_photos_on_place_id", using: :btree

  create_table "place_route_in_areas", force: true do |t|
    t.integer "place_id"
    t.integer "route_id"
  end

  add_index "place_route_in_areas", ["place_id"], name: "index_place_route_in_areas_on_place_id", using: :btree
  add_index "place_route_in_areas", ["route_id"], name: "index_place_route_in_areas_on_route_id", using: :btree

  create_table "place_routes", force: true do |t|
    t.integer "place_id"
    t.integer "route_id"
    t.integer "waypoint_index"
  end

  add_index "place_routes", ["place_id"], name: "index_place_routes_on_place_id", using: :btree
  add_index "place_routes", ["route_id"], name: "index_place_routes_on_route_id", using: :btree

  create_table "places", force: true do |t|
    t.string   "type",                                                                          null: false
    t.string   "name",               limit: 64,                                                 null: false
    t.string   "name_status",        limit: 32,                            default: "Official", null: false
    t.integer  "name_reference",     limit: 2
    t.integer  "int",                limit: 2
    t.string   "alternate_names",    limit: 128
    t.string   "slug"
    t.string   "province",           limit: 64
    t.boolean  "partial_name_match",                                                            null: false
    t.text     "match_names"
    t.text     "reject_names"
    t.integer  "nearby_namesake_id"
    t.integer  "height"
    t.integer  "height_reference",   limit: 2
    t.decimal  "latitude",                       precision: 8,  scale: 6
    t.decimal  "longitude",                      precision: 9,  scale: 6
    t.integer  "area"
    t.decimal  "max_latitude",                   precision: 8,  scale: 6
    t.decimal  "min_latitude",                   precision: 8,  scale: 6
    t.decimal  "max_longitude",                  precision: 9,  scale: 6
    t.decimal  "min_longitude",                  precision: 9,  scale: 6
    t.integer  "parent_area_id"
    t.integer  "forum_id"
    t.boolean  "sub_region",                                               default: false
    t.text     "description"
    t.text     "references"
    t.integer  "ref_place_id"
    t.decimal  "importance",                     precision: 28, scale: 10
    t.integer  "insert_id",                                                                     null: false
    t.integer  "update_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "feature_id"
    t.integer  "area_id"
  end

  add_index "places", ["area_id"], name: "index_places_on_area_id", using: :btree
  add_index "places", ["feature_id"], name: "index_places_on_feature_id", using: :btree
  add_index "places", ["slug"], name: "index_places_on_slug", unique: true, using: :btree

  create_table "route_albums", force: true do |t|
    t.integer "route_id",                 null: false
    t.integer "album_id",                 null: false
    t.boolean "in_title", default: false
  end

  add_index "route_albums", ["album_id"], name: "index_route_albums_on_album_id", using: :btree
  add_index "route_albums", ["route_id"], name: "index_route_albums_on_route_id", using: :btree

  create_table "route_photos", force: true do |t|
    t.integer "route_id",                 null: false
    t.integer "photo_id",                 null: false
    t.boolean "in_title", default: false
  end

  add_index "route_photos", ["photo_id"], name: "index_route_photos_on_photo_id", using: :btree
  add_index "route_photos", ["route_id"], name: "index_route_photos_on_route_id", using: :btree

  create_table "routes", force: true do |t|
    t.string   "type",                                                                           null: false
    t.string   "name",                limit: 128,                                                null: false
    t.string   "alternate_names",     limit: 128
    t.string   "name_status",         limit: 32,                            default: "Official", null: false
    t.text     "equipment"
    t.text     "description"
    t.text     "references"
    t.string   "travel_time",                                                                    null: false
    t.integer  "difficulty"
    t.decimal  "distance",                        precision: 5,  scale: 2
    t.integer  "height_gain"
    t.integer  "height_loss"
    t.integer  "feature_id"
    t.boolean  "partial_name_match"
    t.integer  "insert_id",                                                                      null: false
    t.integer  "update_id"
    t.decimal  "importance",                      precision: 19, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "match_names"
    t.text     "reject_names"
    t.string   "gps_file_name"
    t.string   "gps_content_type"
    t.integer  "gps_file_size"
    t.datetime "gps_updated_at"
    t.integer  "road_id"
    t.integer  "descent_route_id"
    t.text     "access"
    t.boolean  "different_start_end",                                       default: false,      null: false
    t.boolean  "newb",                                                      default: false,      null: false
    t.string   "avalanche_rating"
    t.boolean  "glacier_travel",                                            default: false,      null: false
    t.text     "objective_hazard"
    t.boolean  "seracs",                                                    default: false,      null: false
    t.boolean  "rockfall",                                                  default: false,      null: false
    t.boolean  "river_crossing",                                            default: false,      null: false
    t.integer  "place_id"
  end

  add_index "routes", ["importance"], name: "index_routes_on_importance", using: :btree
  add_index "routes", ["insert_id"], name: "index_routes_on_insert_id", using: :btree
  add_index "routes", ["place_id"], name: "index_routes_on_place_id", using: :btree
  add_index "routes", ["type", "created_at"], name: "index_routes_on_type_and_created_at", using: :btree
  add_index "routes", ["type", "feature_id"], name: "index_routes_on_type_and_feature_id", using: :btree

  create_table "trip_reports", force: true do |t|
    t.string   "title",           limit: 128
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "abstract"
    t.text     "participants",                                          null: false
    t.text     "description"
    t.integer  "route_id",                                              null: false
    t.integer  "user_id",                                               null: false
    t.integer  "update_id"
    t.decimal  "importance",                  precision: 19, scale: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "travel_time"
    t.integer  "topic_id"
    t.datetime "last_liked_at"
    t.datetime "last_comment_at"
    t.integer  "total_comments"
    t.integer  "total_likes"
    t.string   "type"
    t.boolean  "snowshoeing"
    t.boolean  "skiing"
  end

  add_index "trip_reports", ["created_at"], name: "index_trip_reports_on_created_at", using: :btree
  add_index "trip_reports", ["importance"], name: "index_trip_reports_on_importance", using: :btree
  add_index "trip_reports", ["route_id"], name: "index_trip_reports_on_route_id", using: :btree
  add_index "trip_reports", ["topic_id"], name: "index_trip_reports_on_topic_id", using: :btree
  add_index "trip_reports", ["user_id"], name: "index_trip_reports_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                                 default: "",                    null: false
    t.string   "encrypted_password",        limit: 128, default: "",                    null: false
    t.string   "password_salt",                         default: "",                    null: false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "realname",                  limit: 64,                                  null: false
    t.integer  "role_index",                            default: 2,                     null: false
    t.string   "city",                      limit: 32,                                  null: false
    t.string   "province",                  limit: 32,                                  null: false
    t.string   "country",                   limit: 32,                                  null: false
    t.datetime "content_contributer_until"
    t.datetime "paid_contributer_until"
    t.datetime "contributer_until"
    t.text     "description"
    t.string   "home_page",                 limit: 100
    t.integer  "recentGrantedAccessTime",               default: 0
    t.text     "notifications"
    t.datetime "last_visit_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.text     "photo_caption"
    t.string   "last_http_user_agent",      limit: 200
    t.string   "username",                  limit: 64
    t.boolean  "forem_admin",                           default: false
    t.datetime "reset_password_sent_at"
    t.string   "forem_state",                           default: "approved"
    t.boolean  "forem_auto_subscribe",                  default: true
    t.text     "signature"
    t.datetime "forem_last_visit_at"
    t.datetime "forem_first_visit_at"
    t.string   "slug"
    t.datetime "last_photo_uploaded_at",                default: '2013-02-06 08:48:16'
    t.string   "unconfirmed_email"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["created_at"], name: "index_users_on_created_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "versions", force: true do |t|
    t.integer  "versioned_id"
    t.string   "versioned_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "user_name"
    t.text     "modifications"
    t.integer  "number"
    t.integer  "reverted_from"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["created_at"], name: "index_versions_on_created_at", using: :btree
  add_index "versions", ["number"], name: "index_versions_on_number", using: :btree
  add_index "versions", ["tag"], name: "index_versions_on_tag", using: :btree
  add_index "versions", ["user_id", "user_type"], name: "index_versions_on_user_id_and_user_type", using: :btree
  add_index "versions", ["user_name"], name: "index_versions_on_user_name", using: :btree
  add_index "versions", ["versioned_id", "versioned_type"], name: "index_versions_on_versioned_id_and_versioned_type", using: :btree

  create_table "views", force: true do |t|
    t.integer  "user_id"
    t.integer  "viewable_id"
    t.string   "viewable_type"
    t.integer  "count"
    t.integer  "rating"
    t.datetime "current_viewed_at"
    t.datetime "past_viewed_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "views", ["user_id"], name: "index_views_on_user_id", using: :btree
  add_index "views", ["viewable_id"], name: "index_views_on_viewable_id", using: :btree
  add_index "views", ["viewable_type"], name: "index_views_on_viewable_type", using: :btree

  create_table "visits", force: true do |t|
    t.integer  "ip_address_id",                  null: false
    t.integer  "visitable_id",                   null: false
    t.string   "visitable_type",                 null: false
    t.datetime "current_visited_at"
    t.datetime "datetime"
    t.datetime "past_visited_at"
    t.integer  "count",              default: 0
    t.boolean  "facebook_like"
    t.boolean  "google_plus"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "visits", ["ip_address_id"], name: "index_visits_on_ip_address_id", using: :btree
  add_index "visits", ["visitable_id"], name: "index_visits_on_visitable_id", using: :btree
  add_index "visits", ["visitable_type"], name: "index_visits_on_visitable_type", using: :btree

  create_table "waypoints", force: true do |t|
    t.decimal  "latitude",                precision: 8, scale: 6, null: false
    t.decimal  "longitude",               precision: 9, scale: 6, null: false
    t.integer  "height"
    t.string   "location"
    t.string   "difficulty",   limit: 32
    t.text     "description"
    t.integer  "route_id",                                        null: false
    t.integer  "parent_index"
    t.integer  "local_index",                                     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "distance",                precision: 5, scale: 2
    t.string   "icon",         limit: 32
    t.string   "title"
    t.integer  "height_gain"
    t.integer  "height_loss"
  end

  add_index "waypoints", ["route_id"], name: "index_waypoints_on_route_id", using: :btree

end
