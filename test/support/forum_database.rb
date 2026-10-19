module ForumDatabase
  def setup
    @connection = ActiveRecord::Base.connection
    @previous_path = @connection.schema_search_path
    @schema = "article_comments_test_#{SecureRandom.hex(6)}"
    tables = @connection.tables
    @connection.execute("CREATE SCHEMA #{@schema}")
    tables.each do |table|
      @connection.execute("CREATE TABLE #{@schema}.#{table} (LIKE public.#{table} INCLUDING ALL)")
      sequence = nil
      sequence = @connection.select_value("SELECT pg_get_serial_sequence(#{@connection.quote('public.' + table)}, 'id')") if @connection.columns(table).any? { |column| column.name == "id" }
      next unless sequence

      @connection.execute("CREATE SEQUENCE #{@schema}.#{table}_id_seq OWNED BY #{@schema}.#{table}.id")
      @connection.execute("ALTER TABLE #{@schema}.#{table} ALTER COLUMN id SET DEFAULT nextval('#{@schema}.#{table}_id_seq')")
    end
    @connection.schema_search_path = "#{@schema}, public"
    @connection.schema_cache.clear!
    @old_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    @old_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    User.insert_all!([ 10, 11, 12 ].map do |id|
      { id: id, email: "member#{id}@example.test", realname: "Member #{id}", username: "member#{id}",
        city: "", province: "", country: "", forem_admin: id == 12,
        confirmed_at: Time.current, created_at: Time.current, updated_at: Time.current }
    end)
    Thredded::UserDetail.insert_all!([ 10, 11, 12 ].map do |id|
      { user_id: id, moderation_state: 1, created_at: Time.current, updated_at: Time.current }
    end)
    Album.insert_all!([ { id: 20, title: "An album", user_id: 10,
      ref_latitude: 0, ref_longitude: 0, ref_title: "", ref_content: "" } ])
    @article = Album.find(20)
    @user = User.find(11)
    @board = Thredded::Messageboard.create!(name: "Other Regions", description: "Comments")
  end

  def teardown
    ActiveJob::Base.queue_adapter = @old_adapter
    Rails.cache = @old_cache
    @connection.schema_search_path = @previous_path
    @connection.execute("DROP SCHEMA #{@schema} CASCADE")
    @connection.schema_cache.clear!
  end
end
