class RemoveSortKeyFromLemmata < ActiveRecord::Migration
  def up
    remove_column :lemmata, :sort_key
  end

  def down
    add_column :lemmata, :sort_key, :string, limit: 16
  end
end
