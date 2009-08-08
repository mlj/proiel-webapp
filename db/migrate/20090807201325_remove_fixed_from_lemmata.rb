class RemoveFixedFromLemmata < ActiveRecord::Migration
  def self.up
    remove_column :lemmata, :fixed
  end

  def self.down
    add_column :lemmata, :fixed, :boolean, :default => false, :null => false
  end
end
