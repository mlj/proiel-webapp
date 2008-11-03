class ExtendSentenceAlignment < ActiveRecord::Migration
  def self.up
    add_column :sentences, :unalignable, :boolean, :null => false, :default => false
    add_column :sentences, :automatic_alignment, :boolean, :null => true, :default => false
    add_column :sentences, :sentence_alignment_id, :integer, :null => true, :default => nil

    drop_table "sentence_alignments"
  end

  def self.down
    remove_column :sentences, :unalignable

    create_table "sentence_alignments", :id => false, :force => true do |t|
      t.integer  "primary_sentence_id",   :default => 0,     :null => false
      t.integer  "secondary_sentence_id", :default => 0,     :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "automatic",             :default => false, :null => false
    end

    add_index "sentence_alignments", ["secondary_sentence_id"], :name => "index_sentence_alignments_on_secondary_sentence_id"
  end
end
