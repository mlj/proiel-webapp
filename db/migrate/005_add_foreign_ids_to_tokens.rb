class AddForeignIdsToTokens < ActiveRecord::Migration
  def self.up
    add_column :tokens, :foreign_ids, :text
  end

  def self.down
    remove_column :tokens, :foreign_ids
  end
end
