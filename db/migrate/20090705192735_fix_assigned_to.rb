class FixAssignedTo < ActiveRecord::Migration
  def self.up
    change_column :sentences, :assigned_to, :integer, :null => true
  end

  def self.down
    change_column :sentences, :assigned_to, :integer, :null => false
  end
end
