class RemoveMorphtagSourceFromToken < ActiveRecord::Migration
  def self.up
    remove_column :tokens, :morphtag_source
  end

  def self.down
    add_column :tokens, :morphtag_source, :enum, :limit => [:source_ambiguous, :source_unambiguous, :auto_ambiguous, :auto_unambiguous, :manual]
  end
end
