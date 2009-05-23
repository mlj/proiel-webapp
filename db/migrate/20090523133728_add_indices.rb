class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :tokens, [:antecedent_id]
    add_index :tokens, [:form]
    add_index :notes, ["notable_id", "notable_type"]
  end

  def self.down
    remove_index :notes, ["notable_id", "notable_type"]
    remove_index :tokens, [:form]
    remove_index :tokens, [:antecedent_id]
  end
end
