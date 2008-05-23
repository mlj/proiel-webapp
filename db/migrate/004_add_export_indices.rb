class AddExportIndices < ActiveRecord::Migration
  def self.up
    add_index :tokens, :head_id
  end

  def self.down
    remove_index :tokens, :head_id
  end
end
