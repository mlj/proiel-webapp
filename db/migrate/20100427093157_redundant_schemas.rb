class RedundantSchemas < ActiveRecord::Migration
  def self.up
    drop_table :books
  end

  def self.down
    create_table "books", :force => true do |t|
      t.string "title",        :limit => 16, :default => "", :null => false
      t.string "abbreviation", :limit => 8
      t.string "code",         :limit => 8,  :default => "", :null => false
    end
  end
end
