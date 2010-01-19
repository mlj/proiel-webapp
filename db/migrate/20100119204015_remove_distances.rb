class RemoveDistances < ActiveRecord::Migration
  def self.up
    remove_column(:tokens, :antecedent_dist_in_words)
    remove_column(:tokens, :antecedent_dist_in_sentences)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
