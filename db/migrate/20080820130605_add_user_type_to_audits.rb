class AddUserTypeToAudits < ActiveRecord::Migration
  def self.up
    add_column :audits, :user_type, :string, :null => false, :limit => 16, :default => nil

    execute("UPDATE audits SET user_type = 'User'");
  end

  def self.down
    remove_column :audits, :user_type
  end
end
