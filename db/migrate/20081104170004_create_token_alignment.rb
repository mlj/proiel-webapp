class CreateTokenAlignment < ActiveRecord::Migration
  def self.up
    add_column :tokens, :token_alignment_id, :integer, :null => true, :default => nil
    add_column :tokens, :automatic_token_alignment, :boolean, :null => true, :default => false
  end

  def self.down
    remove_column :tokens, :token_alignment_id
    remove_column :tokens, :automatic_token_alignment
  end
end
