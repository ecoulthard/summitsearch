class AddLastPostAtToForemTopics < ActiveRecord::Migration
  def change
    add_column :forem_topics, :last_post_at, :datetime
  end
end
