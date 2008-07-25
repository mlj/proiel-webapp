class AddDictionaryFieldsToLemma < ActiveRecord::Migration
  def self.up
    add_column :lemmata, :sort_key, :string, :limit => 16
    add_column :lemmata, :foreign_ids, :text
    add_column :lemmata, :conjecture, :boolean
    add_column :lemmata, :unclear, :boolean
    add_column :lemmata, :reconstructed, :boolean
    add_column :lemmata, :nonexistant, :boolean
    add_column :lemmata, :inflected, :boolean
    rename_column :dictionary_references, :dictionary_identifier, :dictionary
    rename_column :dictionary_references, :entry_identifier, :entry
  end

  def self.down
#    rename_column :dictionary_references, :dictionary, :dictionary_identifier
#    rename_column :dictionary_references, :entry, :entry_identifier
    remove_column :lemmata, :sort_key
    remove_column :lemmata, :foreign_ids
    remove_column :lemmata, :conjecture
    remove_column :lemmata, :unclear
    remove_column :lemmata, :reconstructed
    remove_column :lemmata, :nonexistant
    remove_column :lemmata, :inflected
  end
end
