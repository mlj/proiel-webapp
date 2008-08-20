class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes, :options => 'DEFAULT CHARSET=UTF8' do |t|
      t.string :notable_type, :limit => 64, :null => false
      t.integer :notable_id, :null => false
      t.string :originator_type, :limit => 64, :null => false
      t.integer :originator_id, :null => false
      t.text :contents, :null => false, :default => ''

      t.timestamps
    end

    create_table :import_sources do |t|
      t.string :tag, :limit => 16, :null => false
      t.string :summary, :limit => 256, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :import_sources
    drop_table :notes
  end
end
