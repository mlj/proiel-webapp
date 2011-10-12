class NukePresentation < ActiveRecord::Migration
  def self.up
    remove_column :sentences, :presentation
    remove_column :source_divisions, :presentation
  end

  def self.down
    add_column :sentences, :presentation, :text, :null => false
    add_column :source_divisions, :presentation, :text, :null => false
  end
end
