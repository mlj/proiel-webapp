class UpdateSourceMorphology < ActiveRecord::Migration
  def up
    rename_column :tokens, :source_morphology, :source_morphology_tag
    change_column :tokens, :source_morphology_tag, :string, :limit => 11
  end

  def down
    change_column :tokens, :source_morphology_tag, :string, :limit => 17
    rename_column :tokens, :source_morphology_tag, :source_morphology
  end
end
