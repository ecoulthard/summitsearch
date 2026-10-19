# One-shot PostgreSQL import. No Forem gem, model callbacks, jobs, or mailers.
class ForemImport
  class UnsafeImport < StandardError; end

  SOURCE = "forem-v1"
  SOURCES = %w[forem_categories forem_forums forem_topics forem_posts forem_subscriptions users].freeze
  DESTINATIONS = %w[thredded_categories thredded_messageboards thredded_posts thredded_private_posts
    thredded_private_topics thredded_private_users thredded_topic_categories thredded_topics
    thredded_user_details thredded_messageboard_users thredded_user_preferences
    thredded_user_messageboard_preferences thredded_user_topic_read_states
    thredded_user_private_topic_read_states thredded_messageboard_groups thredded_user_topic_follows
    thredded_post_moderation_records thredded_notifications_for_private_topics
    thredded_notifications_for_followed_topics thredded_messageboard_notifications_for_followed_topics
    thredded_user_post_notifications].freeze
  STATES = { "approved" => 1, "pending_review" => 0, "pending_moderation" => 0,
    "spam" => 2, "rejected" => 2, "blocked" => 2, "" => 0 }.freeze
  EPOCH = Time.utc(1970, 1, 1).freeze

  def initialize
    @connection = ActiveRecord::Base.connection
    @models = {}
  end

  # SELECTs only. Run again under locks before making any import writes.
  def preflight
    errors = []
    missing = (SOURCES + destinations + [ "forum_import_runs" ]).reject { |name| @connection.data_source_exists?(name) }
    return { errors: [ "Missing tables: #{missing.join(', ')}; run db:migrate first" ] } if missing.any?

    counts = SOURCES.to_h { |name| [ name, count(name) ] }
    occupied = destinations.select { |name| count(name).positive? }
    errors << "Destination tables must be empty: #{occupied.join(', ')}" if occupied.any?
    errors << "An import is already recorded; reruns are refused" if count("forum_import_runs").positive?

    states = { "forem_topics" => "state", "forem_posts" => "state", "users" => "forem_state" }.to_h do |name, column|
      values = @connection.select_rows("SELECT #{column}, COUNT(*) FROM #{name} GROUP BY #{column}")
      unknown = values.reject { |value, _| STATES.key?(value.to_s.downcase) }
      errors << "Unknown moderation states in #{name}: #{unknown.map(&:first).inspect}" if unknown.any?
      [ name, values.to_h ]
    end

    { "forem_forums.category_id" => [ "forem_categories", true ],
      "forem_topics.forum_id" => [ "forem_forums", false ],
      "forem_posts.topic_id" => [ "forem_topics", false ] }.each do |reference, (parent, optional)|
      name, column = reference.split(".")
      orphaned = scalar("SELECT COUNT(*) FROM #{name} s LEFT JOIN #{parent} p ON p.id = s.#{column} WHERE p.id IS NULL #{'AND s.' + column + ' IS NOT NULL' if optional}")
      errors << "#{orphaned} orphaned #{reference} references" if orphaned.positive?
    end

    warnings = {}
    %w[forem_topics forem_posts].each do |name|
      warnings["#{name}_missing_authors"] = scalar("SELECT COUNT(*) FROM #{name} s LEFT JOIN users u ON u.id = s.user_id WHERE s.user_id IS NOT NULL AND u.id IS NULL")
      warnings["#{name}_missing_timestamps"] = scalar("SELECT COUNT(*) FROM #{name} WHERE created_at IS NULL OR updated_at IS NULL")
    end
    warnings["skipped_subscriptions_missing_users"] = scalar("SELECT COUNT(*) FROM forem_subscriptions s LEFT JOIN users u ON u.id = s.subscriber_id WHERE u.id IS NULL")
    warnings["skipped_subscriptions_missing_topics"] = scalar("SELECT COUNT(*) FROM forem_subscriptions s LEFT JOIN forem_topics t ON t.id = s.topic_id WHERE t.id IS NULL")
    warnings["duplicate_subscriptions"] = scalar("SELECT COALESCE(SUM(n - 1), 0) FROM (SELECT COUNT(*) n FROM forem_subscriptions GROUP BY subscriber_id, topic_id HAVING COUNT(*) > 1) duplicates")
    { source_counts: counts, moderation_states: states, warnings: warnings, errors: errors }
  end

  def run!
    raise UnsafeImport, "PostgreSQL is required" unless @connection.adapter_name == "PostgreSQL"
    initial = preflight
    raise UnsafeImport, initial[:errors].join("; ") if initial[:errors].any?

    @connection.transaction(requires_new: true) do
      @connection.execute("SET LOCAL lock_timeout = '5s'")
      # These table locks also serialize concurrent import attempts. Recheck
      # destination emptiness only after acquiring the locks.
      @connection.execute("LOCK TABLE #{(destinations + [ 'forum_import_runs' ]).sort.join(', ')} IN SHARE ROW EXCLUSIVE MODE")
      @connection.execute("LOCK TABLE #{SOURCES.sort.join(', ')} IN SHARE MODE")
      report = preflight
      raise UnsafeImport, report[:errors].join("; ") if report[:errors].any?

      @user_ids = User.pluck(:id).to_set
      import_groups
      import_boards
      import_topics
      import_posts
      import_users
      import_follows
      update_counters
      verify!(report)
      counts = destinations.to_h { |name| [ name, count(name) ] }
      model("forum_import_runs").insert_all!([ { source: SOURCE, counts: counts, completed_at: Time.current } ])
      reset_sequences
      report.merge(destination_counts: counts)
    end
  end

  private

  def destinations
    @destinations ||= (DESTINATIONS + @connection.tables.grep(/\Athredded_/)).uniq.sort
  end

  def model(name)
    @models[name] ||= Class.new(ActiveRecord::Base) { self.table_name = name }
  end

  def count(name)
    scalar("SELECT COUNT(*) FROM #{name}")
  end

  def scalar(sql)
    @connection.select_value(sql).to_i
  end

  def transfer(source, destination)
    model(source).find_in_batches(batch_size: 500) do |batch|
      model(destination).insert_all!(batch.map { |record| yield(record.attributes) })
    end
  end

  def timestamps(row)
    { created_at: row["created_at"] || row["updated_at"] || EPOCH,
      updated_at: row["updated_at"] || row["created_at"] || EPOCH }
  end

  def author(id)
    id if @user_ids.include?(id)
  end

  def state(value)
    STATES.fetch(value.to_s.downcase)
  end

  def import_groups
    transfer("forem_categories", "thredded_messageboard_groups") do |row|
      timestamps(row).merge(id: row["id"], forem_category_id: row["id"], name: row["name"],
        position: row["position"] || 0, forem_slug: row["slug"])
    end
  end

  def import_boards
    transfer("forem_forums", "thredded_messageboards") do |row|
      { id: row["id"], forem_forum_id: row["id"], name: row["name"].presence || "Forum #{row['id']}",
        slug: "legacy-forum-#{row['id']}", description: row["description"], position: row["position"] || 0,
        messageboard_group_id: row["category_id"], forem_slug: row["slug"], forem_views_count: row["views_count"],
        created_at: EPOCH, updated_at: EPOCH }
    end
  end

  def import_topics
    sanitizer = Rails::HTML5::FullSanitizer.new
    transfer("forem_topics", "thredded_topics") do |row|
      title = CGI.unescapeHTML(sanitizer.sanitize(row["subject"].to_s)).strip.presence || "Topic #{row['id']}"
      attrs = timestamps(row).merge(id: row["id"], forem_topic_id: row["id"],
        title: title, slug: "legacy-topic-#{row['id']}", hash_id: "forem-#{row['id']}",
        messageboard_id: row["forum_id"], user_id: author(row["user_id"]),
        sticky: !!row["pinned"], locked: row["locked"],
        moderation_state: row["hidden"] ? 2 : state(row["state"]),
        last_post_at: row["last_post_at"] || row["created_at"] || EPOCH,
        forem_subject: row["subject"], forem_slug: row["slug"], forem_state: row["state"],
        forem_hidden: row["hidden"], forem_views_count: row["views_count"], forem_user_id: row["user_id"])
      %w[album photo trip_report place area feature].each { |name| attrs["#{name}_id"] = row["#{name}_id"] }
      attrs
    end
  end

  def import_posts
    model("forem_posts").find_in_batches(batch_size: 500) do |batch|
      topics = model("thredded_topics").where(id: batch.map { |post| post["topic_id"] }).index_by(&:id)
      rows = batch.map do |record|
        row = record.attributes
        topic = topics.fetch(row["topic_id"])
        timestamps(row).merge(id: row["id"], forem_post_id: row["id"], content: row["text"], source: "forem",
          postable_id: row["topic_id"], messageboard_id: topic["messageboard_id"], user_id: author(row["user_id"]),
          moderation_state: post_state(state(row["state"]), topic["moderation_state"]),
          forem_reply_to_id: row["reply_to_id"], forem_user_id: row["user_id"],
          forem_state: row["state"], forem_notified: row["notified"])
      end
      model("thredded_posts").insert_all!(rows)
    end
  end

  def import_users
    transfer("users", "thredded_user_details") do |row|
      timestamps(row).merge(user_id: row["id"], moderation_state: state(row["forem_state"]),
        latest_activity_at: row["forem_last_visit_at"], last_seen_at: row["forem_last_visit_at"])
    end
  end

  def post_state(post, topic)
    return 2 if post == 2 || topic == 2
    return 0 if post == 0 || topic == 0
    1
  end

  def import_follows
    @connection.execute(<<~SQL)
      INSERT INTO thredded_user_topic_follows (user_id, topic_id, created_at, reason)
      SELECT DISTINCT s.subscriber_id, s.topic_id, t.created_at, 0
      FROM forem_subscriptions s JOIN users u ON u.id = s.subscriber_id
      JOIN thredded_topics t ON t.id = s.topic_id
    SQL
  end

  def update_counters
    @connection.execute(<<~SQL)
      UPDATE thredded_topics t SET posts_count = (SELECT COUNT(*) FROM thredded_posts p WHERE p.postable_id = t.id),
      last_user_id = (SELECT user_id FROM thredded_posts p WHERE p.postable_id = t.id AND p.moderation_state = t.moderation_state ORDER BY created_at DESC, id DESC LIMIT 1),
      last_post_at = COALESCE((SELECT created_at FROM thredded_posts p WHERE p.postable_id = t.id AND p.moderation_state = t.moderation_state ORDER BY created_at DESC, id DESC LIMIT 1), t.created_at)
    SQL
    @connection.execute(<<~SQL)
      UPDATE thredded_messageboards b SET
      topics_count = (SELECT COUNT(*) FROM thredded_topics t WHERE t.messageboard_id = b.id),
      posts_count = (SELECT COUNT(*) FROM thredded_posts p WHERE p.messageboard_id = b.id),
      last_topic_id = (SELECT id FROM thredded_topics t WHERE t.messageboard_id = b.id AND t.moderation_state = 1 ORDER BY last_post_at DESC, id DESC LIMIT 1)
    SQL
    @connection.execute(<<~SQL)
      UPDATE thredded_user_details d SET
      topics_count = (SELECT COUNT(*) FROM thredded_topics t WHERE t.user_id = d.user_id),
      posts_count = (SELECT COUNT(*) FROM thredded_posts p WHERE p.user_id = d.user_id)
    SQL
  end

  def verify!(report)
    { "forem_categories" => "thredded_messageboard_groups", "forem_forums" => "thredded_messageboards",
      "forem_topics" => "thredded_topics", "forem_posts" => "thredded_posts", "users" => "thredded_user_details" }.each do |source, destination|
      raise UnsafeImport, "Count mismatch: #{source}" unless report[:source_counts].fetch(source) == count(destination)
    end
    changed_bodies = scalar("SELECT COUNT(*) FROM forem_posts f JOIN thredded_posts t ON t.id = f.id WHERE f.text IS DISTINCT FROM t.content")
    raise UnsafeImport, "Post content verification failed" if changed_bodies.positive?
    follows = scalar(<<~SQL)
      SELECT COUNT(*) FROM (
        SELECT DISTINCT s.subscriber_id, s.topic_id FROM forem_subscriptions s
        JOIN users u ON u.id = s.subscriber_id JOIN forem_topics t ON t.id = s.topic_id
      ) valid_follows
    SQL
    raise UnsafeImport, "Subscription count mismatch" unless follows == count("thredded_user_topic_follows")
  end

  def reset_sequences
    # ALTER SEQUENCE RESTART is transactional, unlike PostgreSQL setval().
    (destinations + [ "forum_import_runs" ]).each do |name|
      sequence = @connection.select_value("SELECT pg_get_serial_sequence(#{@connection.quote(name)}, 'id')")
      next unless sequence
      next_id = scalar("SELECT COALESCE(MAX(id), 0) + 1 FROM #{name}")
      @connection.execute("ALTER SEQUENCE #{@connection.quote_table_name(sequence)} RESTART WITH #{next_id}")
    end
  end
end
