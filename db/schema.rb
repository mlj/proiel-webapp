# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080814143556) do

  create_table "announcements", :force => true do |t|
    t.text     "message"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer  "role_id",    :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "audits", :force => true do |t|
    t.integer "auditable_id",   :limit => 11
    t.string  "auditable_type"
    t.string  "action"
    t.text    "changes"
    t.integer "version",        :limit => 11, :default => 0
    t.integer "changeset_id",   :limit => 11
  end

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["changeset_id"], :name => "index_audits_on_changeset_id"

  create_table "bookmarks", :force => true do |t|
    t.integer "user_id",     :limit => 11,                                :default => 0,         :null => false
    t.integer "source_id",   :limit => 11,                                :default => 0,         :null => false
    t.integer "sentence_id", :limit => 11,                                :default => 0,         :null => false
    t.enum    "flow",        :limit => [:browsing, :annotation, :review], :default => :browsing, :null => false
  end

  add_index "bookmarks", ["user_id"], :name => "fk_bookmarks_user"

  create_table "books", :force => true do |t|
    t.string "title",        :limit => 16, :default => "", :null => false
    t.string "abbreviation", :limit => 8
    t.string "code",         :limit => 8,  :default => "", :null => false
  end

  create_table "changesets", :force => true do |t|
    t.datetime "created_at",               :null => false
    t.integer  "user_id",    :limit => 11
  end

  add_index "changesets", ["created_at"], :name => "index_changesets_on_created_at"

  create_table "dictionaries", :force => true do |t|
    t.string "identifier", :limit => 32,  :default => "", :null => false
    t.string "title",      :limit => 128, :default => "", :null => false
    t.text   "fulltitle"
    t.text   "source"
  end

  create_table "dictionary_entries", :force => true do |t|
    t.integer "dictionary_id", :limit => 11, :default => 0,  :null => false
    t.string  "identifier",    :limit => 32, :default => "", :null => false
    t.text    "data",                                        :null => false
  end

  create_table "dictionary_references", :force => true do |t|
    t.integer  "lemma_id",            :limit => 11, :default => 0, :null => false
    t.string   "dictionary"
    t.string   "entry"
    t.integer  "dictionary_entry_id", :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lemmata", :force => true do |t|
    t.string   "lemma",         :limit => 64, :default => "",    :null => false
    t.string   "variant",       :limit => 16
    t.string   "language",      :limit => 3
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pos",           :limit => 2,  :default => "",    :null => false
    t.string   "short_gloss",   :limit => 64
    t.text     "full_gloss"
    t.boolean  "fixed",                       :default => false, :null => false
    t.string   "sort_key",      :limit => 16
    t.text     "foreign_ids"
    t.boolean  "conjecture"
    t.boolean  "unclear"
    t.boolean  "reconstructed"
    t.boolean  "nonexistant"
    t.boolean  "inflected"
  end

  add_index "lemmata", ["lemma"], :name => "index_lemmata_on_lemma"
  add_index "lemmata", ["variant"], :name => "index_lemmata_on_variant"
  add_index "lemmata", ["language"], :name => "index_lemmata_on_lang"

  create_table "roles", :force => true do |t|
    t.string "code",        :limit => 16, :default => "", :null => false
    t.string "description", :limit => 64, :default => "", :null => false
  end

  create_table "sentence_alignments", :id => false, :force => true do |t|
    t.integer  "primary_sentence_id",   :limit => 11, :default => 0,   :null => false
    t.integer  "secondary_sentence_id", :limit => 11, :default => 0,   :null => false
    t.float    "confidence",                          :default => 0.0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sentence_alignments", ["secondary_sentence_id"], :name => "index_sentence_alignments_on_secondary_sentence_id"

  create_table "sentences", :force => true do |t|
    t.integer  "source_id",          :limit => 11, :default => 0,     :null => false
    t.integer  "book_id",            :limit => 2,  :default => 0,     :null => false
    t.integer  "chapter",            :limit => 2,  :default => 0,     :null => false
    t.integer  "sentence_number",    :limit => 11, :default => 0,     :null => false
    t.boolean  "bad_alignment_flag",               :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "annotated_by",       :limit => 11
    t.datetime "annotated_at"
    t.integer  "reviewed_by",        :limit => 11
    t.datetime "reviewed_at"
  end

  add_index "sentences", ["source_id", "book_id", "sentence_number"], :name => "sentence_number_index", :unique => true
  add_index "sentences", ["book_id"], :name => "index_sentences_on_book_id"

  create_table "slash_edges", :force => true do |t|
    t.integer "slasher_id", :limit => 11
    t.integer "slashee_id", :limit => 11
  end

  add_index "slash_edges", ["slasher_id", "slashee_id"], :name => "index_slash_edges_on_slasher_and_slashee", :unique => true

  create_table "sources", :force => true do |t|
    t.string  "code",         :limit => 64, :default => "", :null => false
    t.text    "title"
    t.string  "language",     :limit => 3,  :default => "", :null => false
    t.text    "edition"
    t.text    "source"
    t.text    "editor"
    t.text    "url"
    t.integer "alignment_id", :limit => 11
    t.string  "abbreviation", :limit => 64, :default => "", :null => false
  end

  create_table "tokens", :force => true do |t|
    t.integer  "sentence_id",       :limit => 11,                                                                                    :default => 0,     :null => false
    t.integer  "verse",             :limit => 2
    t.integer  "token_number",      :limit => 3,                                                                                     :default => 0,     :null => false
    t.string   "morphtag",          :limit => 17
    t.string   "form",              :limit => 64
    t.integer  "lemma_id",          :limit => 11
    t.string   "relation",          :limit => 20
    t.integer  "head_id",           :limit => 3
    t.enum     "morphtag_source",   :limit => [:source_ambiguous, :source_unambiguous, :auto_ambiguous, :auto_unambiguous, :manual]
    t.enum     "sort",              :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end, :prodrop],  :default => :text, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_morphtag",   :limit => 17
    t.string   "source_lemma",      :limit => 32
    t.text     "foreign_ids"
    t.boolean  "contraction",                                                                                                        :default => false, :null => false
    t.enum     "nospacing",         :limit => [:before, :after, :both]
    t.string   "presentation_form", :limit => 128
    t.integer  "presentation_span", :limit => 11
    t.boolean  "emendation",                                                                                                         :default => false, :null => false
    t.boolean  "abbreviation",                                                                                                       :default => false, :null => false
    t.boolean  "capitalisation",                                                                                                     :default => false, :null => false
    t.enum     "info_status",       :limit => [:new, :acc, :acc_gen, :acc_disc, :acc_inf, :old]
  end

  add_index "tokens", ["sentence_id", "token_number"], :name => "index_tokens_on_sentence_id_and_token_number", :unique => true
  add_index "tokens", ["lemma_id"], :name => "index_tokens_on_lemma_id"
  add_index "tokens", ["relation"], :name => "index_tokens_on_relation"
  add_index "tokens", ["morphtag"], :name => "index_tokens_on_morphtag"
  add_index "tokens", ["head_id"], :name => "index_tokens_on_head_id"

  create_table "users", :force => true do |t|
    t.string   "login",                                   :default => "",        :null => false
    t.string   "email",                                   :default => "",        :null => false
    t.string   "crypted_password",          :limit => 40, :default => "",        :null => false
    t.string   "salt",                      :limit => 40, :default => "",        :null => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "last_name",                 :limit => 60, :default => "",        :null => false
    t.string   "first_name",                :limit => 60, :default => "",        :null => false
    t.string   "preferences"
    t.integer  "role_id",                   :limit => 3,  :default => 1,         :null => false
    t.string   "state",                                   :default => "passive", :null => false
    t.datetime "deleted_at"
  end

end
