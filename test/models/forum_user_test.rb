# Run standalone; no forum schema or global legacy fixtures are required.
ENV["RAILS_ENV"] = "test"
require_relative "../../config/environment"
require "minitest/autorun"
require_relative "../../db/migrate/20261018000100_add_case_insensitive_username_index"

class ForumUserTest < Minitest::Test
  def setup
    @connection = ActiveRecord::Base.connection
    @connection.begin_transaction(joinable: false)
    # PostgreSQL temporary tables shadow the real tables only for this session.
    @connection.execute("CREATE TEMPORARY TABLE thredded_messageboards (id bigint PRIMARY KEY, forem_forum_id integer, name text, locked boolean DEFAULT false) ON COMMIT DROP")
    @connection.execute("CREATE TEMPORARY TABLE forem_memberships (id serial PRIMARY KEY, group_id integer, member_id integer) ON COMMIT DROP")
    @connection.execute("CREATE TEMPORARY TABLE forem_moderator_groups (id serial PRIMARY KEY, forum_id integer, group_id integer) ON COMMIT DROP")
    @tables = [ Thredded::Messageboard, LegacyForumMembership, LegacyForumModeratorGroup ].to_h { |model| [ model, model.table_name ] }
    schema = @connection.select_value("SELECT nspname FROM pg_namespace WHERE oid = pg_my_temp_schema()")
    @tables.each { |model, name| model.table_name = "#{schema}.#{name}" }
    @connection.schema_cache.clear!
    Thredded::Messageboard.reset_column_information
    User.reset_column_information
    @connection.execute("INSERT INTO thredded_messageboards (id, forem_forum_id, name) VALUES (1, 99, 'Assigned'), (2, 100, 'Other'), (99, NULL, 'Unmapped')")
    @connection.execute("INSERT INTO forem_memberships (group_id, member_id) VALUES (7, 101), (8, 102), (9, 101)")
    @connection.execute("INSERT INTO forem_moderator_groups (forum_id, group_id) VALUES (99, 7), (99, 9), (100, 8)")
  end

  def teardown
    @connection.rollback_transaction
    @tables.each { |model, name| model.table_name = name }
    @connection.schema_cache.clear!
    Thredded::Messageboard.reset_column_information
    User.reset_column_information
  end

  def member(id: 101, admin: false, role: 2, username: nil)
    User.instantiate("id" => id, "forem_admin" => admin, "role_index" => role,
      "realname" => "Forum Member", "username" => username, "slug" => "forum-member-#{id}")
  end

  def test_configuration_uses_existing_devise_users_and_sender
    assert_equal User, Thredded.user_class
    assert_includes User.devise_modules, :database_authenticatable
    assert_equal :current_user, Thredded.current_user_method
    assert_equal :username, Thredded.user_name_column
    assert_equal :display_name, Thredded.user_display_name_method
    assert_equal Rails.application.config.notifier_email.presence || "notifier@summitsearch.org", Thredded.email_from
    refute Thredded.content_visible_while_pending_moderation
    context = Object.new
    context.define_singleton_method(:main_app) { Rails.application.routes.url_helpers }
    user = member
    assert_equal Rails.application.routes.url_helpers.user_path(user), Thredded.user_path(context, user)
  end

  def test_display_names_preserve_fallback_for_legacy_accounts
    assert_equal "Forum Member", member.thredded_display_name
    assert_equal "handle", member(username: "handle").thredded_display_name
  end

  def test_forum_admin_can_administer_and_moderate_every_board
    user = member(admin: true)
    assert user.thredded_admin?
    assert_equal [ 1, 2, 99 ], user.thredded_can_moderate_messageboards.order(:id).pluck(:id)
    assert Thredded::MessageboardPolicy.new(user, Thredded::Messageboard.find(2)).update?
  end

  def test_site_admin_is_not_automatically_a_forum_admin
    user = member(id: 103, role: 0)
    assert user.is_admin?
    refute user.thredded_admin?
    assert_empty user.thredded_can_moderate_messageboards
  end

  def test_moderator_grants_are_scoped_by_explicit_legacy_mapping
    user = member
    assert_equal ForumUser, user.method(:thredded_can_moderate_messageboards).owner
    assert user.persisted?
    assert Thredded::Messageboard.table_exists?
    assert_includes Thredded::Messageboard.column_names, "forem_forum_id"
    assert_equal [ 7, 9 ], LegacyForumMembership.where(member_id: user.id).order(:group_id).pluck(:group_id)
    assert_equal [ 1 ], user.thredded_can_moderate_messageboards.pluck(:id)
    assigned = Thredded::Messageboard.find(1)
    other = Thredded::Messageboard.find(2)
    assert Thredded::MessageboardPolicy.new(user, assigned).moderate?
    refute Thredded::MessageboardPolicy.new(user, other).moderate?
    refute user.thredded_can_moderate_messageboard?(Thredded::Messageboard.find(99))
    refute Thredded::MessageboardPolicy.new(user, assigned).update?
    assert LegacyForumMembership.first.readonly?
  end

  def test_ordinary_members_can_post_but_guests_cannot
    board = Thredded::Messageboard.find(2)
    assert Thredded::MessageboardPolicy.new(member(id: 103), board).post?
    refute Thredded::MessageboardPolicy.new(Thredded::NullUser.new, board).post?
    board.locked = true
    refute Thredded::MessageboardPolicy.new(member, board).post?
  end

  def test_missing_mapping_fails_closed
    @connection.execute("ALTER TABLE thredded_messageboards DROP COLUMN forem_forum_id")
    Thredded::Messageboard.reset_column_information
    assert_empty member.thredded_can_moderate_messageboards
    assert_empty User.new.thredded_can_moderate_messageboards
  end

  def test_host_role_gates_are_removed_only_from_forum_controllers
    filters = ->(controller) { controller._process_action_callbacks.select { |callback| callback.kind == :before }.map(&:filter) }
    [ :authenticate_user!, :editor_required, :admin_required ].each do |filter|
      assert_includes filters.call(ApplicationController), filter
      refute_includes filters.call(Thredded::ApplicationController), filter
    end
    assert_includes filters.call(Thredded::TopicsController), :thredded_require_login!
  end

  def test_username_audit_detects_legacy_issues_without_modifying_users
    @connection.execute("CREATE TEMPORARY TABLE forum_audit_users (id serial PRIMARY KEY, username text) ON COMMIT DROP")
    @connection.execute("INSERT INTO forum_audit_users (username) VALUES (NULL), (''), ('   '), (' Alice '), ('alice'), ('Bob')")
    users = Class.new(ActiveRecord::Base) { self.table_name = "forum_audit_users" }
    assert_equal({ users: 6, null_usernames: 1, blank_usernames: 2,
      whitespace_usernames: 2, duplicate_case_insensitive_groups: 1 }, ForumUserAudit.report(users.all))
    assert_equal " Alice ", users.find(4).username
  end

  def test_username_index_preserves_nulls_and_rejects_case_collisions
    @connection.execute("CREATE TEMPORARY TABLE users (id serial PRIMARY KEY, username text) ON COMMIT DROP")
    ActiveRecord::Migration.suppress_messages { AddCaseInsensitiveUsernameIndex.new.up }
    @connection.execute("INSERT INTO users (username) VALUES (NULL), (NULL), ('ForumHandle')")
    assert_raises ActiveRecord::RecordNotUnique do
      ActiveRecord::Base.transaction(requires_new: true) do
        @connection.execute("INSERT INTO users (username) VALUES ('forumhandle')")
      end
    end
    assert_equal 3, @connection.select_value("SELECT count(*) FROM users")
  end

  def test_username_index_preflight_rejects_conflicting_legacy_names
    @connection.execute("CREATE TEMPORARY TABLE users (id serial PRIMARY KEY, username text) ON COMMIT DROP")
    @connection.execute("INSERT INTO users (username) VALUES ('ForumHandle'), ('forumhandle')")
    error = assert_raises ActiveRecord::MigrationError do
      ActiveRecord::Migration.suppress_messages { AddCaseInsensitiveUsernameIndex.new.up }
    end
    assert_includes error.message, "thredded:users:audit"
  end
end
