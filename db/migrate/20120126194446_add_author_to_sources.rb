class AddAuthorToSources < ActiveRecord::Migration
  def change
    add_column :sources, :author, :text, :limit => 128, :null => true
    add_column :sources, :edition, :text, :limit => 128, :null => true
  end
end
