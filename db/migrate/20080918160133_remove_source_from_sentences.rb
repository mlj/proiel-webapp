class RemoveSourceFromSentences < ActiveRecord::Migration
  def self.up
    remove_column :sentences, :source_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
