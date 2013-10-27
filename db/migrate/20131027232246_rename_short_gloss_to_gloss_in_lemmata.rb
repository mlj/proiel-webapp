class RenameShortGlossToGlossInLemmata < ActiveRecord::Migration
  def up
    rename_column :lemmata, :short_gloss, :gloss
  end

  def down
    rename_column :lemmata, :gloss, :short_gloss
  end
end
