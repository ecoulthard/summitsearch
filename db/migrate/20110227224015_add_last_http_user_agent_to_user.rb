class AddLastHttpUserAgentToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :last_http_user_agent, :string, :limit => 200
  end

  def self.down
    remove_column :users, :last_http_user_agent
  end
end
