class AddCaseInsensitiveUsernameIndex < ActiveRecord::Migration[8.0]
  def up
    duplicates = select_value(<<~SQL)
      SELECT COUNT(*) FROM (
        SELECT lower(username) FROM users
        WHERE username IS NOT NULL
        GROUP BY lower(username) HAVING COUNT(*) > 1
      ) duplicate_usernames
    SQL
    if duplicates.to_i.positive?
      raise ActiveRecord::MigrationError, "Resolve case-insensitive username duplicates before migrating; run rails thredded:users:audit"
    end

    add_index :users, "lower(username)", unique: true, name: "index_users_on_lower_username"
  end

  def down
    remove_index :users, name: "index_users_on_lower_username"
  end
end
