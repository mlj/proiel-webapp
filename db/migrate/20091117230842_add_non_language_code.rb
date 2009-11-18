class AddNonLanguageCode < ActiveRecord::Migration
  def self.up
    Language.create!(:iso_code => "non", :name => "Old Norse")
  end

  def self.down
    Language.find_by_iso_code("non").destroy
  end
end
