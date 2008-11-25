class CreateDependencyAlignments < ActiveRecord::Migration
  def self.up
    add_column :tokens, :dependency_alignment_id, :integer, :null => true, :default => nil
    add_index :tokens, [:dependency_alignment_id]

    create_table :dependency_alignment_terminations do |t|
      t.integer :token_id, :null => false
      t.integer :source_id, :null => false
    end

    add_index :dependency_alignment_terminations, [:token_id]
    add_index :dependency_alignment_terminations, [:source_id]
  end

  def self.down
    drop_table :dependency_alignment_terminations

    remove_column :tokens, :dependency_alignment_id
  end
end
