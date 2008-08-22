class DitchActsAsAuditedUserHandling < ActiveRecord::Migration
  def self.up
    change_column :audits, :user_id, :integer, :null => true
    change_column :audits, :user_type, :string, :null => true
  end

  def self.down
    change_column :audits, :user_id, :integer, :null => false
    change_column :audits, :user_type, :string, :null => false
  end
end
