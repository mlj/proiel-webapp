class IndexTokensOnTokenAlignmentId < ActiveRecord::Migration
  def self.up
    add_index :tokens, :token_alignment_id
  end

  def self.down
    remove_index :tokens, :token_alignment_id
  end
end
