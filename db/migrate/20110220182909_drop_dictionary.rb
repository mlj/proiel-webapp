class DropDictionary < ActiveRecord::Migration
  def self.up
    drop_table "dictionaries"
    drop_table "dictionary_entries"
    drop_table "dictionary_references"
  end

  def self.down
    create_table "dictionaries", :force => true do |t|
      t.string "identifier", :limit => 32,  :default => "", :null => false
      t.string "title",      :limit => 128, :default => "", :null => false
      t.text   "fulltitle"
      t.text   "source"
    end

    create_table "dictionary_entries", :force => true do |t|
      t.integer "dictionary_id",               :default => 0,  :null => false
      t.string  "identifier",    :limit => 32, :default => "", :null => false
      t.text    "data",                                        :null => false
    end

    create_table "dictionary_references", :force => true do |t|
      t.integer  "lemma_id",            :default => 0, :null => false
      t.string   "dictionary"
      t.string   "entry"
      t.integer  "dictionary_entry_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
