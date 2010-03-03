class FixSchemaFieldLimits < ActiveRecord::Migration
  def self.up
    change_column :sources, :title, :string, :limit => 128, :null => false, :default => ""
    change_column :sources, :tracked_references, :string, :limit => 128, :null => false, :default => ""
    change_column :sources, :reference_format, :string, :limit => 256, :null => false, :default => ""
  end

  def self.down
    change_column :sources, :reference_format, :string, :limit => 256, :null => false
    change_column :sources, :tracked_references, :string, :limit => 128
    change_column :sources, :title, :text
  end
end
