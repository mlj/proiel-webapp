class FixAssignedTo < ActiveRecord::Migration
  def self.up
    change_column :sentences, :assigned_to, :integer, :null => true
    add_index :sentences, [:assigned_to]
  end

  def self.down
    change_column :sentences, :assigned_to, :integer, :null => false
  end
end
