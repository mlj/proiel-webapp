class RemoveCodeFromSources < ActiveRecord::Migration
  def up
    remove_column :sources, :code
  end

  def down
    add_column :sources, :code, :string, :limit => 64,  :default => "", :null => false
  end
end
