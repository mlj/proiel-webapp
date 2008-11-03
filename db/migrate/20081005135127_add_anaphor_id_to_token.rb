class AddAnaphorIdToToken < ActiveRecord::Migration
  def self.up
    add_column(:tokens, 'anaphor_id', :integer)
    add_index(:tokens, 'anaphor_id', :unique => true)
  end

  def self.down
    remove_column(:tokens, 'anaphor_id')
  end
end
