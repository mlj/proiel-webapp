class AddAnnotationQueue < ActiveRecord::Migration
  def self.up
    add_column :sentences, :assigned_to, :integer, :null => false

    drop_table :bookmarks
  end

  def self.down
    create_table "bookmarks", :force => true do |t|
      t.integer "user_id",                                                  :default => 0,         :null => false
      t.integer "source_id",                                                :default => 0,         :null => false
      t.integer "sentence_id",                                              :default => 0,         :null => false
      t.enum    "flow",        :limit => [:browsing, :annotation, :review], :default => :browsing, :null => false
    end

    remove_column :sentences, :assigned_to
  end
end
