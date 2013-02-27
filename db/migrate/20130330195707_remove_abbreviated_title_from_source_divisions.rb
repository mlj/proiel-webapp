class RemoveAbbreviatedTitleFromSourceDivisions < ActiveRecord::Migration
  def up
    remove_column :source_divisions, :abbreviated_title
  end

  def down
    add_column :source_divisions, :abbreviated_title, :string, :limit => 128, :default => "", :null => false
  end
end
