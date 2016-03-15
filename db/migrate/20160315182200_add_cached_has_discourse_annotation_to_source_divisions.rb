class AddCachedHasDiscourseAnnotationToSourceDivisions < ActiveRecord::Migration
  def change
    add_column :source_divisions, :cached_has_discourse_annotation, :boolean
  end
end
