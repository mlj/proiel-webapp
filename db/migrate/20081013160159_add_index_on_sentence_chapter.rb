class AddIndexOnSentenceChapter < ActiveRecord::Migration
  def self.up
    add_index(:sentences, :chapter)
  end

  def self.down
    remove_index(:sentences, :chapter)
  end
end
