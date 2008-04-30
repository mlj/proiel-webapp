class InitialSchema < ActiveRecord::Migration
  OPTIONS = 'DEFAULT CHARSET=UTF8'

  def self.up
    create_table :roles, :force => true, :options => OPTIONS do |t|
      t.column :code, :string, :limit => 16, :null => false
      t.column :description, :string, :limit => 64, :null => false
    end

    Role.create(:code => 'reader', :description => 'Reader')
    Role.create(:code => 'annotator', :description => 'Annotator')
    Role.create(:code => 'reviewer', :description => 'Reviewer')
    Role.create(:code => 'administrator', :description => 'Administrator')

    create_table :users, :force => true, :options => OPTIONS do |t|
      t.column :login,                     :string, :null => false
      t.column :email,                     :string, :null => false
      t.column :crypted_password,          :string, :limit => 40, :null => false
      t.column :salt,                      :string, :limit => 40, :null => false
      t.column :created_at,                :datetime, :null => false
      t.column :updated_at,                :datetime, :null => false
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime

      t.column :activation_code, :string, :limit => 40
      t.column :activated_at, :datetime

      t.column :last_name, :string, :limit => 60, :null => false
      t.column :first_name, :string, :limit => 60, :null => false
      t.column :preferences, :string

      t.column :role_id, :integer, :limit => 3, :null => false, :default => Role.find_by_code('reader').id
    end

    create_table :sources, :force => true, :options => OPTIONS do |t|
      t.column :code, :string, :null => false, :limit => 64
      t.column :title, :text
      t.column :language, :string, :null => false, :limit => 3
      t.column :edition, :text
      t.column :source, :text
      t.column :editor, :text
      t.column :url, :text
      t.column :alignment_id, :integer, :null => true
      t.string :abbreviation, :limit => 64, :null => false
    end

    create_table :books, :force => true, :options => OPTIONS do |t|
      t.column :title, :string, :null => false, :limit => 16
      t.column :abbreviation, :string, :null => false, :limit => 8
      t.column :code, :string, :null => false, :limit => 8
    end
    
    Book.create :code => 'MATT', :abbrev => 'Matt.', :title => 'Matthew'
    Book.create :code => 'MARK', :abbrev => 'Mark', :title => 'Mark'
    Book.create :code => 'LUKE', :abbrev => 'Luke', :title => 'Luke'
    Book.create :code => 'JOHN', :abbrev => 'John', :title => 'John'
    Book.create :code => 'ACTS', :abbrev => 'Acts', :title => 'Acts'
    Book.create :code => 'ROM', :abbrev => 'Rom.', :title => 'Romans'
    Book.create :code => '1COR', :abbrev => '1 Cor.', :title => '1 Corinthians'
    Book.create :code => '2COR', :abbrev => '2 Cor.', :title => '2 Corinthians'
    Book.create :code => 'GAL', :abbrev => 'Gal.', :title => 'Galatians'
    Book.create :code => 'EPH', :abbrev => 'Eph.', :title => 'Ephesians'
    Book.create :code => 'PHIL', :abbrev => 'Phil.', :title => 'Philippians'
    Book.create :code => 'COL', :abbrev => 'Col.', :title => 'Colossians'
    Book.create :code => '1THESS', :abbrev => '1 Thess.', :title => '1 Thessalonians'
    Book.create :code => '2THESS', :abbrev => '2 Thess.', :title => '2 Thessalonians'
    Book.create :code => '1TIM', :abbrev => '1 Tim.', :title => '1 Timothy'
    Book.create :code => '2TIM', :abbrev => '2. Tim.', :title => '2 Timothy'
    Book.create :code => 'TIT', :abbrev => 'Tit.', :title => 'Titus'
    Book.create :code => 'PHILEM', :abbrev => 'Philem.', :title => 'Philemon'
    Book.create :code => 'HEB', :abbrev => 'Heb.', :title => 'Hebrews'
    Book.create :code => 'JAS', :abbrev => 'Jas.', :title => 'James'
    Book.create :code => '1PET', :abbrev => '1 Pet.', :title => '1 Peter'
    Book.create :code => '2PET', :abbrev => '2 Pet.', :title => '2 Peter'
    Book.create :code => '1JOHN', :abbrev => '1 John', :title => '1 John'
    Book.create :code => '2JOHN', :abbrev => '2 John', :title => '2 John'
    Book.create :code => '3JOHN', :abbrev => '3 John', :title => '3 John'
    Book.create :code => 'JUDE', :abbrev => 'Jude', :title => 'Jude'
    Book.create :code => 'REV', :abbrev => 'Rev.', :title => 'Revelation'

    create_table :sentences, :force => true, :options => OPTIONS do |t|
      t.column :source_id, :integer, :null => false
      t.column :book_id, :integer, :null => false, :limit => 2
      t.column :chapter, :integer, :null => false, :limit => 2
      t.column :sentence_number, :integer, :null => false
      t.integer  :annotated_by
      t.datetime :annotated_at
      t.integer  :reviewed_by
      t.datetime :reviewed_at
      t.boolean  :bad_alignment_flag, :null => false, :default => false

      t.timestamps
    end

    add_index :sentences, :book_id
    add_index :sentences, ["source_id", "book_id", "sentence_number"], :name => :sentence_number_index, :unique => true

    create_table :tokens, :force => true, :options => OPTIONS do |t|
      t.column :sentence_id, :integer, :null => false
      t.column :verse, :integer, :limit => 2, :default => nil
      t.column :token_number, :integer, :null => false, :limit => 3
      t.column :morphtag, :string, :limit => 17, :default => nil
      t.column :form, :string, :limit => 64, :default => nil
      t.column :lemma_id, :integer, :default => nil
      t.column :relation, :string, :limit => 20, :default => nil
      t.column :head_id, :integer, :limit => 3, :default => nil
      t.enum   :morphtag_source, :limit => [ :source_ambiguous, :source_unambiguous, :auto_ambiguous, :auto_unambiguous, :manual ], :null => true, :default => nil
      t.string :composed_form, :limit => 64, :default => nil
      t.enum   :sort, :limit => [:word, :empty, :fused_morpheme, :enclitic, :nonspacing_punctuation], :null => false, :default => :word
      t.enum   :morphtag_performance, :limit => [:failed, :overridden, :suggested, :picked], :default => nil
      t.string :source_morphtag, :limit => 17, :default => nil
      t.string :source_lemma, :limit => 32, :default => nil

      t.timestamps
    end

    add_index :tokens, [:sentence_id, :token_number], :unique => true
    add_index :tokens, :lemma_id
    add_index :tokens, :relation

    create_table :lemmata, :force => true, :options => OPTIONS do |t|
      t.string  :lemma,       :limit => 64,  :null => false
      t.string  :variant,     :limit => 16,  :null => true,  :default => nil
      t.string  :language,    :limit => 3,   :null => false
      t.string  :pos,         :limit => 2,   :null => false
      t.string  :short_gloss, :limit => 64,  :null => true,  :default => nil
      t.string  :full_gloss,  :limit => 256, :null => true,  :default => nil
      t.boolean :fixed,                      :null => false, :default => false
      t.timestamps
    end

    add_index :lemmata, :lemma
    add_index :lemmata, :variant
    add_index :lemmata, :lang
    
    create_table :sentence_alignments, :force => true, :options => OPTIONS do |t|
      t.integer :primary_sentence_id, :null => false
      t.integer :secondary_sentence_id, :null => false
      t.float :confidence, :null => false

      t.timestamps
    end
    remove_column :sentence_alignments, :id

    add_index :sentence_alignments, :secondary_sentence_id

    create_table :audits, :force => true, :options => OPTIONS do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :action, :string
      t.column :changes, :text
      t.column :version, :integer, :default => 0
      t.column :changeset_id, :integer
    end
    
    add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
    add_index :audits, [:user_id, :user_type], :name => 'user_index'
    add_index :audits, :created_at  
    add_index :audits, :changeset_id

    create_table :jobs, :force => true, :options => OPTIONS do |t|
      t.string :name, :limit => 64, :null => false
      t.text :parameters
      t.integer :user_id, :null => false
      t.datetime :started_at
      t.datetime :finished_at
      t.column :result, :enum, :limit => [ :successful, :failed, :aborted ]
      t.integer :source_id
      t.boolean :audited, :null => false
      t.text :log

      t.timestamps
    end

    create_table :bookmarks, :force => true, :options => OPTIONS do |t|
      t.column :user_id, :integer, :null => false
      t.column :source_id, :integer, :null => false
      t.column :sentence_id, :integer, :null => false
      t.column :flow, :enum, :null => false, :limit => [ :browsing, :annotation, :review ]
    end

    add_index :bookmarks, ["user_id"], :name => "fk_bookmarks_user"

    create_table :changesets, :force => true, :options => OPTIONS do |t|
      t.integer  :changer_id, :null => false
      t.string   :changer_type, :limit => 16, :null => false
      t.datetime :created_at, :null => false
    end

    add_index :changesets, [:created_at], :name => "index_changesets_on_created_at"
    add_index :changesets, [:user_id], :name => "index_changesets_on_user_id"

    create_table :slash_edges do |t|
      t.integer :slasher_id, :null => false
      t.integer :slashee_id, :null => false
    end

    add_index :slash_edges, [:slasher_id, :slashee_id], :unique => true

    create_table :dictionaries, :options => 'DEFAULT CHARSET=UTF8' do |t|
      t.string "identifier", :limit => 32, :null => false
      t.string "title",      :limit => 128, :null => false
      t.text   "fulltitle"
      t.text   "source"
    end

    create_table :dictionary_entries, :options => 'DEFAULT CHARSET=UTF8' do |t|
      t.integer "dictionary_id",               :null => false
      t.string  "identifier",    :limit => 32, :null => false
      t.text    "data",                        :null => false
    end

    create_table :dictionary_references do |t|
      t.references :lemma, :null => false
      t.string :dictionary_identifier, :null => false
      t.string :entry_identifier, :null => false
      t.references :dictionary_entry
      t.timestamps
    end

  end

  def self.down
    drop_table :dictionary_references
    drop_table :dictionary_entries
    drop_table :dictionaries
    drop_table :slash_edges
    drop_table :changesets
    drop_table :bookmarks
    drop_table :jobs
    drop_table :audits
    drop_table :roles
    drop_table :sentence_alignments
    drop_table :lemmata
    drop_table :tokens
    drop_table :sentences
    drop_table :books
    drop_table :sources
    drop_table :users
  end
end
