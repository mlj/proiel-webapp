class RemoveUserTypeFromAudits < ActiveRecord::Migration
  def self.up
    remove_column :audits, :user_type
  end

  def self.down
    add_column :audits, :user_type, :string, :default => nil
  end
end
