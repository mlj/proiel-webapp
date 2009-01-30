class UseAntecedentIdInsteadOfAnaphorId < ActiveRecord::Migration
  def self.up
    remove_column :tokens, :anaphor_id
    add_column :tokens, :antecedent_id, :integer
  end

  def self.down
    remove_column :tokens, :antecedent_id
    add_column :tokens, :anaphor_id, :integer
  end
end
