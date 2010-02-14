class MigrateToDevise < ActiveRecord::Migration
  def self.up
    # From
    #t.string   "login",                                   :default => "",        :null => false
    #t.string   "email",                                   :default => "",        :null => false
    #t.string   "crypted_password",          :limit => 40, :default => "",        :null => false
    #t.string   "salt",                      :limit => 40, :default => "",        :null => false
    #t.datetime "created_at",                                                     :null => false
    #t.datetime "updated_at",                                                     :null => false
    #t.string   "remember_token"
    #t.datetime "remember_token_expires_at"
    #t.string   "activation_code",           :limit => 40
    #t.datetime "activated_at"
    #t.string   "last_name",                 :limit => 60, :default => "",        :null => false
    #t.string   "first_name",                :limit => 60, :default => "",        :null => false
    #t.string   "preferences"
    #t.integer  "role_id",                                 :default => 1,         :null => false
    #t.string   "state",                                   :default => "passive", :null => false
    #t.datetime "deleted_at"

    # To
    #t.string   "email",                                             :null => false
    #t.string   "encrypted_password",   :limit => 40,                :null => false
    #t.string   "password_salt",                                     :null => false
    #t.string   "confirmation_token",   :limit => 20
    #t.datetime "confirmed_at"
    #t.datetime "confirmation_sent_at"
    #t.string   "reset_password_token", :limit => 20
    #t.string   "remember_token",       :limit => 20
    #t.datetime "remember_created_at"
    #t.integer  "sign_in_count"
    #t.datetime "current_sign_in_at"
    #t.datetime "last_sign_in_at"
    #t.string   "current_sign_in_ip"
    #t.string   "last_sign_in_ip"
    #t.integer  "failed_attempts",                    :default => 0
    #t.string   "unlock_token",         :limit => 20
    #t.datetime "locked_at"
    #t.datetime "created_at"
    #t.datetime "updated_at"

    # Leave as is
    # t.string   "login"
    #
    # t.string   "last_name",                 :limit => 60, :default => "",        :null => false
    # t.string   "first_name",                :limit => 60, :default => "",        :null => false
    # t.string   "preferences"
    # t.integer  "role_id",                                 :default => 1,         :null => false

    remove_column "users", "activation_code"
    rename_column "users", "activated_at", "confirmed_at"

    add_column "users", "confirmation_token", :string, :limit => 20
    change_column "users", "email", :string, :null => false

    add_column "users", "confirmation_sent_at", :datetime
    add_column "users", "reset_password_token", :string, :limit => 20

    remove_column "users", "remember_token"
    remove_column "users", "remember_token_expires_at"
    add_column "users", "remember_token", :string, :limit => 20
    add_column "users", "remember_created_at", :datetime

    rename_column "users", "crypted_password", "encrypted_password"
    change_column "users", "encrypted_password", :string, :limit => 40, :null => false

    rename_column "users", "salt", "password_salt"
    change_column "users", "password_salt", :string, :null => false

    add_column "users", "sign_in_count", :integer
    add_column "users", "current_sign_in_at", :datetime
    add_column "users", "last_sign_in_at", :datetime
    add_column "users", "current_sign_in_ip", :string
    add_column "users", "last_sign_in_ip", :string
    add_column "users", "failed_attempts", :integer, :default => 0
    add_column "users", "unlock_token", :string, :limit => 20
    add_column "users", "locked_at", :datetime

    change_column "users", "created_at", :datetime
    change_column "users", "updated_at", :datetime

    remove_column "users", "deleted_at"
    remove_column "users", "state"

    add_index :users, :email,                :unique => true
    add_index :users, :confirmation_token,   :unique => true
    add_index :users, :reset_password_token, :unique => true
  end

  def self.down
    raise
  end
end
