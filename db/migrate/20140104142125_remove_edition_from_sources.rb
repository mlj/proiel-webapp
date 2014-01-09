class RemoveEditionFromSources < ActiveRecord::Migration
  def up
    remove_column :sources, :edition
  end

  def down
    add_column :sources, :edition, :text, limit: 255
  end
end
