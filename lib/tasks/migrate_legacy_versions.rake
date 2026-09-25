namespace :legacy_versions do
  desc "Migrate legacy versions to paper_trail_versions"
  task migrate: :environment do
    # 1. Configuration Setup
    legacy_table = "versions"
    puts "Starting migration from #{legacy_table} using legacy naming convention..."

    # 2. Extract unique records using 'versioned_type' and 'versioned_id'
    distinct_records = ActiveRecord::Base.connection.execute(
      "SELECT DISTINCT versioned_type, versioned_id FROM #{legacy_table}"
    )

    count = 0

    # 3. Iterate and translate
    distinct_records.each do |row|
      type = row["versioned_type"]
      id   = row["versioned_id"]

      klass = type.constantize rescue next
      current_record = klass.find_by(id: id)
      next unless current_record

      # Fetch using corrected columns
      vestal_history = ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([
                                                "SELECT * FROM #{legacy_table} WHERE versioned_type = ? AND versioned_id = ? ORDER BY number DESC",
                                                type, id
                                              ])
      )

      state_snapshot = current_record.attributes.dup

      vestal_history.each do |v_ver|
        modifications = nil
        raw_mod = v_ver["modifications"]

        begin
          modifications = YAML.safe_load(raw_mod, permitted_classes: [Symbol, Time, ActiveSupport::TimeWithZone])
        rescue
          begin
            modifications = ActiveSupport::JSON.decode(raw_mod)
          rescue
            modifications = {}
          end
        end

        next if modifications.blank?

        modifications.each do |attribute_name, values|
          next unless values.respond_to?(:first) && values.size >= 2
          old_value = values.first
          state_snapshot[attribute_name] = old_value if state_snapshot.key?(attribute_name)
        end

        serialized_object = ActiveSupport::JSON.encode(state_snapshot)

        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql_array([
                                                  "INSERT INTO paper_trail_versions (item_type, item_id, event, object, whodunnit, created_at) VALUES (?, ?, ?, ?, ?, ?)",
                                                  type,
                                                  id,
                                                  (v_ver["number"].to_i == 1 ? "create" : "update"),
                                                  serialized_object,
                                                  v_ver["user_id"] || v_ver["user_name"],
                                                  v_ver["created_at"]
                                                ])
        )
        count += 1
      end
    end

    puts "Success! Rebuilt #{count} version records into paper_trail_versions."
  end
end
