class SwitchToTeiHeader < ActiveRecord::Migration
  def self.up
    remove_column :sources, :url
    remove_column :sources, :editor
    remove_column :sources, :source
    remove_column :sources, :edition
    add_column :sources, :tei_header, :text, :null => false
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
