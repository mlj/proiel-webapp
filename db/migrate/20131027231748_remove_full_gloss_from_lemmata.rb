class RemoveFullGlossFromLemmata < ActiveRecord::Migration
  def up
    remove_column :lemmata, :full_gloss
  end

  def down
    add_column :lemmata, :full_gloss, :string
  end
end
