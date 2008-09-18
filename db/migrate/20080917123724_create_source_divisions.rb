class Book < ActiveRecord::Base
  has_many :sentences
end

class CreateSourceDivisions < ActiveRecord::Migration
  def self.up
    create_table :source_divisions do |t|
       t.integer :source_id, :null => false
       t.integer :position, :null => false
       t.string  :title, :limit => 128, :null => false
       t.string  :abbreviated_title, :limit => 128, :null => false
       t.string  :fields, :limit => 128, :null => false
       t.integer :aligned_source_division_id, :null => true
  
       t.timestamps
    end
 
    add_column :sentences, :source_division_id, :integer, :null => false

    Sentence.reset_column_information
    SourceDivision.reset_column_information
    Sentence.disable_auditing

    Source.transaction do
      Source.all.each do |source|
        Sentence.find(:all, :conditions => { :source_id => source.id }).each do |sentence| # Source.sentence is gone
          book = Book.find(sentence.book_id) # Book model is gone
          title = book.title
          abbreviated_title = book.abbreviation
          fields = "book=#{book.code}"

          sentence.source_division = 
            source.source_divisions.find_or_create_by_fields(:fields => fields,
                                                             :title => title,
                                                             :abbreviated_title => abbreviated_title,
                                                             :position => source.source_divisions.count + 1)
          sentence.save_without_validation! # validation will fail since source_division is NULL
        end
      end
    end

    remove_index :sentences, :name => :sentence_number_index
    add_index :sentences, [:source_division_id, :sentence_number]
    remove_index :sentences, :name => :index_sentences_on_book_id
    remove_column :sentences, :book_id
    remove_column :sources, :alignment_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
