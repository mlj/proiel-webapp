class AddDistanceAttributesToToken < ActiveRecord::Migration
  def self.up
    add_column(:tokens, :antecedent_dist_in_words, :integer)
    add_column(:tokens, :antecedent_dist_in_sentences, :integer)
  end

  def self.down
    remove_column(:tokens, :antecedent_dist_in_words)
    remove_column(:tokens, :antecedent_dist_in_sentences)
  end
end
