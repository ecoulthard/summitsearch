# Standalone integration tests in a disposable PostgreSQL schema.
ENV["RAILS_ENV"] = "test"
require_relative "../../config/environment"
require "minitest/autorun"

class ForemImportTest < Minitest::Test
  BODY = "<p>Original HTML &amp; text</p>[[photo=42]]".freeze
  TABLES = (ForemImport::SOURCES + ForemImport::DESTINATIONS + [ "forum_import_runs" ]).freeze

  def setup
    @connection = ActiveRecord::Base.connection
    @previous_path = @connection.schema_search_path
    @schema = "forum_import_test_#{SecureRandom.hex(6)}"
    @connection.execute("CREATE SCHEMA #{@schema}")
    TABLES.each do |table|
      @connection.execute("CREATE TABLE #{@schema}.#{table} (LIKE public.#{table} INCLUDING ALL)")
      # LIKE copies sequence defaults pointing at public. Replace each with
      # an owned sequence so neither the import nor its tests touch public IDs.
      @connection.execute("CREATE SEQUENCE #{@schema}.#{table}_id_seq OWNED BY #{@schema}.#{table}.id")
      @connection.execute("ALTER TABLE #{@schema}.#{table} ALTER COLUMN id SET DEFAULT nextval('#{@schema}.#{table}_id_seq')")
    end
    @connection.schema_search_path = "#{@schema}, public"
    @connection.schema_cache.clear!
    User.reset_column_information
    seed
  end

  def teardown
    @connection.schema_search_path = @previous_path
    @connection.execute("DROP SCHEMA #{@schema} CASCADE")
    @connection.schema_cache.clear!
    User.reset_column_information
  end

  def seed
    @connection.execute("INSERT INTO users (id,email,realname,city,province,country,forem_state,created_at,updated_at) VALUES (10,'one@example.test','One','','','','approved','2014-01-02','2014-01-03'),(11,'two@example.test','Two','','','','pending_review','2014-01-02','2014-01-03')")
    @connection.execute("INSERT INTO forem_categories (id,name,slug,position) VALUES (5,'Regional','regional',3)")
    @connection.execute("INSERT INTO forem_forums (id,name,slug,category_id,position,views_count) VALUES (20,'Mountains','admin',5,4,123)")
    @connection.execute(<<~SQL)
      INSERT INTO forem_topics (id,forum_id,user_id,subject,slug,state,hidden,pinned,album_id,photo_id,trip_report_id,place_id,area_id,feature_id,created_at,updated_at) VALUES
      (100,20,10,'<a href="/albums/91">Trip &amp; photos</a>','trip','approved',false,true,91,92,93,94,95,96,'2014-01-02','2014-01-03'),
      (101,20,10,'Hidden','hidden','approved',true,false,NULL,NULL,NULL,NULL,NULL,NULL,'2014-01-02','2014-01-03'),
      (102,20,11,'Pending','pending','pending_review',false,false,NULL,NULL,NULL,NULL,NULL,NULL,'2014-01-02','2014-01-03')
    SQL
    @connection.execute(<<~SQL)
      INSERT INTO forem_posts (id,topic_id,user_id,text,state,reply_to_id,created_at,updated_at) VALUES
      (200,100,10,#{@connection.quote(BODY)},'approved',NULL,'2014-01-02','2014-01-03'),
      (201,100,11,'Review me','pending_review',200,'2014-01-03','2014-01-04'),
      (202,101,10,'Hidden reply','approved',NULL,'2014-01-04','2014-01-05'),
      (203,100,11,'Spam','spam',NULL,'2014-01-05','2014-01-06'),
      (204,102,11,'Pending topic reply','approved',NULL,'2014-01-06','2014-01-07'),
      (205,100,999,'Deleted author','approved',200,'2014-01-07','2014-01-08')
    SQL
    @connection.execute("INSERT INTO forem_subscriptions (subscriber_id,topic_id) VALUES (10,100),(10,100),(11,101),(999,100),(10,999)")
  end

  def test_preflight_is_read_only_and_reports_data_quality
    report = @connection.transaction do
      @connection.execute("SET TRANSACTION READ ONLY")
      ForemImport.new.preflight
    end
    assert_empty report[:errors]
    assert_equal 6, report[:source_counts]["forem_posts"]
    assert_equal 1, report[:warnings]["forem_posts_missing_authors"]
    assert_equal 1, report[:warnings]["duplicate_subscriptions"]
    assert_equal 1, report[:warnings]["skipped_subscriptions_missing_users"]
    assert_equal 1, report[:warnings]["skipped_subscriptions_missing_topics"]
    assert_equal 0, count("thredded_posts")
    assert_equal 0, count("forum_import_runs")
  end

  def test_import_preserves_content_links_and_ids_without_notifications
    events = []
    callback = ->(*args) { events << args }
    ActiveSupport::Notifications.subscribed(callback, /enqueue\.active_job|deliver\.action_mailer/) do
      result = ForemImport.new.run!
      assert_equal 6, result[:destination_counts]["thredded_posts"]
    end
    assert_empty events
    topic = row("thredded_topics", 100)
    assert_equal "Trip & photos", topic["title"]
    assert_equal "trip", topic["forem_slug"]
    assert_equal "legacy-topic-100", topic["slug"]
    assert_equal 91, topic["album_id"]
    assert_equal 96, topic["feature_id"]
    assert topic["sticky"]
    assert_equal 100, topic["forem_topic_id"]
    assert_equal Time.utc(2014, 1, 2), topic["created_at"]
    assert_equal Time.utc(2014, 1, 3), topic["updated_at"]
    post = row("thredded_posts", 200)
    assert_equal BODY, post["content"]
    assert_equal "forem", post["source"]
    assert_equal 200, row("thredded_posts", 201)["forem_reply_to_id"]
    assert_nil row("thredded_posts", 205)["user_id"]
    assert_equal 999, row("thredded_posts", 205)["forem_user_id"]
    assert_equal 2, count("thredded_user_topic_follows")
    assert_equal 20, row("thredded_messageboards", 20)["forem_forum_id"]
    assert_equal 5, row("thredded_messageboard_groups", 5)["forem_category_id"]
    assert_equal 1, count("forum_import_runs")
    assert_equal 6, count("forem_posts")
  end

  def test_hidden_and_pending_content_is_not_promoted_and_counters_are_rebuilt
    ForemImport.new.run!
    assert_equal 0, row("thredded_posts", 201)["moderation_state"]
    assert_equal 2, row("thredded_topics", 101)["moderation_state"]
    assert_equal 2, row("thredded_posts", 202)["moderation_state"]
    assert_equal 2, row("thredded_posts", 203)["moderation_state"]
    assert_equal 0, row("thredded_posts", 204)["moderation_state"]
    assert_equal 4, row("thredded_topics", 100)["posts_count"]
    assert_equal 3, row("thredded_messageboards", 20)["topics_count"]
    assert_equal 100, row("thredded_messageboards", 20)["last_topic_id"]
    assert_nil row("thredded_topics", 100)["last_user_id"]
    details = @connection.select_one("SELECT * FROM thredded_user_details WHERE user_id = 11")
    assert_equal 0, details["moderation_state"]
    assert_equal 3, details["posts_count"]
  end

  def test_rerun_and_nonempty_destinations_are_refused_without_overwrites
    ForemImport.new.run!
    @connection.execute("UPDATE thredded_posts SET content = 'New edit' WHERE id = 200")
    assert_raises(ForemImport::UnsafeImport) { ForemImport.new.run! }
    assert_equal "New edit", row("thredded_posts", 200)["content"]
    @connection.execute("DELETE FROM forum_import_runs")
    assert_raises(ForemImport::UnsafeImport) { ForemImport.new.run! }
  end

  def test_failure_rolls_back_rows_ledger_and_sequence_changes
    importer = Class.new(ForemImport) do
      private
      def reset_sequences
        super
        raise "Simulated failure after sequence reset"
      end
    end
    assert_raises(RuntimeError) { importer.new.run! }
    assert_equal 0, count("thredded_posts")
    assert_equal 0, count("thredded_user_details")
    assert_equal 0, count("forum_import_runs")
    assert_equal 6, count("forem_posts")
    assert_equal false, @connection.select_value("SELECT is_called FROM #{@schema}.thredded_posts_id_seq")
    ForemImport.new.run!
    id = @connection.select_value("INSERT INTO thredded_posts (postable_id,messageboard_id,moderation_state,created_at,updated_at) VALUES (100,20,1,NOW(),NOW()) RETURNING id")
    assert_equal 206, id
  end

  def test_structural_orphans_and_unknown_states_abort_before_writes
    @connection.execute("UPDATE forem_posts SET topic_id = 999 WHERE id = 200")
    assert_match(/orphaned forem_posts.topic_id/, ForemImport.new.preflight[:errors].join)
    assert_raises(ForemImport::UnsafeImport) { ForemImport.new.run! }
    @connection.execute("UPDATE forem_posts SET topic_id = 100, state = 'unrecognized' WHERE id = 200")
    assert_match(/Unknown moderation states/, ForemImport.new.preflight[:errors].join)
    assert_equal 0, count("thredded_topics")
  end

  def test_missing_schema_and_recorded_empty_import_are_refused
    @connection.execute("INSERT INTO forum_import_runs (source,counts,completed_at) VALUES ('forem-v1','{}',NOW())")
    assert_raises(ForemImport::UnsafeImport) { ForemImport.new.run! }
    @connection.execute("DROP TABLE #{@schema}.thredded_posts")
    # No fallback to public tables when using the isolated schema for this check.
    @connection.schema_search_path = @schema
    @connection.schema_cache.clear!
    assert_match(/Missing tables.*thredded_posts/, ForemImport.new.preflight[:errors].join)
  end

  private

  def count(table)
    @connection.select_value("SELECT count(*) FROM #{table}")
  end

  def row(table, id)
    @connection.select_one("SELECT * FROM #{table} WHERE id = #{id}")
  end
end
