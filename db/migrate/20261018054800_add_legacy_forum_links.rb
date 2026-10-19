class AddLegacyForumLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :thredded_messageboards, :forem_forum_id, :integer
    add_index :thredded_messageboards, :forem_forum_id, unique: true
    add_column :thredded_messageboards, :forem_slug, :string
    add_column :thredded_messageboards, :forem_views_count, :integer
    add_column :thredded_messageboard_groups, :forem_category_id, :integer
    add_index :thredded_messageboard_groups, :forem_category_id, unique: true
    add_column :thredded_messageboard_groups, :forem_slug, :string

    add_column :thredded_topics, :forem_topic_id, :integer
    add_index :thredded_topics, :forem_topic_id, unique: true
    %i[album photo trip_report place area feature].each do |association|
      add_column :thredded_topics, :"#{association}_id", :integer
      add_index :thredded_topics, :"#{association}_id"
    end
    add_column :thredded_topics, :forem_subject, :text
    add_column :thredded_topics, :forem_slug, :string
    add_column :thredded_topics, :forem_state, :string
    add_column :thredded_topics, :forem_user_id, :integer
    add_column :thredded_topics, :forem_hidden, :boolean
    add_column :thredded_topics, :forem_views_count, :integer

    add_column :thredded_posts, :forem_post_id, :integer
    add_index :thredded_posts, :forem_post_id, unique: true
    add_column :thredded_posts, :forem_reply_to_id, :integer
    add_column :thredded_posts, :forem_user_id, :integer
    add_column :thredded_posts, :forem_state, :string
    add_column :thredded_posts, :forem_notified, :boolean

    create_table :forum_import_runs do |t|
      t.string :source, null: false
      t.jsonb :counts, null: false
      t.datetime :completed_at, null: false
      t.index :source, unique: true
    end
  end
end
