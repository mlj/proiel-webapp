class AddUserTypeToAudits < ActiveRecord::Migration
  def self.up
    add_column :audits, :user_type, :string, :limit => 8
    add_column :audits, :username, :string, :limit => 8
    execute("UPDATE audits SET user_type = 'User'")
  end

  def self.down
    remove_column :audits, :username
    remove_column :audits, :user_type
  end
end
