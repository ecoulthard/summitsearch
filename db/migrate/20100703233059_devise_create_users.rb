class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      #t.database_authenticatable :null => false
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""
      #t.confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      #t.recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      #t.rememberable
      t.datetime :remember_created_at
      #t.trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at
      t.string :full_name, :null => false, :limit => 64
      t.integer :role_index, :null => false, :limit => 3, :default => User::ROLES.index("Author")
      t.string :city, :null => false, :limit => 32
      t.string :province, :null => false, :limit => 32
      t.string :country, :null => false, :limit => 32
      t.datetime :content_contributer_until
      t.datetime :paid_contributer_until
      t.datetime :contributer_until
      t.text :description, :limit => 5000
      t.string :home_page, :limit => 100
      t.integer :recentGrantedAccessTime, :default => 0 #From recommendations
      t.text :notifications, :limit => 5000
      t.datetime :last_visit_at

      t.timestamps
      #t.encryptable
      t.string :password_salt
    end

    add_index :users, :email,                :unique => true
    add_index :users, :confirmation_token,   :unique => true
    add_index :users, :reset_password_token, :unique => true
    # add_index :users, :unlock_token,         :unique => true
  end

  def self.down
    drop_table :users
  end
end
