class AddCachedCitationToSourceDivisions < ActiveRecord::Migration
  def change
    add_column :source_divisions, :cached_citation, :string, limit: 128
  end
end
