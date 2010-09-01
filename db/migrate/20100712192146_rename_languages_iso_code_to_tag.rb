class RenameLanguagesIsoCodeToTag < ActiveRecord::Migration
  def self.up
    rename_column :languages, :iso_code, :tag
  end

  def self.down
    rename_column :languages, :tag, :iso_code
  end
end
