class AddAdditionalMetadataToSources < ActiveRecord::Migration
  def change
    add_column :sources, :additional_metadata, :text
  end
end
