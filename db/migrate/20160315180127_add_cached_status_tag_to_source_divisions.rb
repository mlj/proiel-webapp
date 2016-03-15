class AddCachedStatusTagToSourceDivisions < ActiveRecord::Migration
  def change
    add_column :source_divisions, :cached_status_tag, :string, limit: 12
  end
end
