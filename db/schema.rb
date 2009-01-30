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

ActiveRecord::Schema.define(:version => 20090130155652) do

  create_table "announcements", :force => true do |t|
    t.text     "message"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.string   "action"
    t.text     "changes"
    t.integer  "version",        :default => 0
    t.integer  "user_id",        :default => 0
    t.datetime "created_at",                    :null => false
  end

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"

  create_table "bookmarks", :force => true do |t|
    t.integer "user_id",                                                  :default => 0,         :null => false
    t.integer "source_id",                                                :default => 0,         :null => false
    t.integer "sentence_id",                                              :default => 0,         :null => false
    t.enum    "flow",        :limit => [:browsing, :annotation, :review], :default => :browsing, :null => false
  end

  add_index "bookmarks", ["user_id"], :name => "fk_bookmarks_user"

  create_table "books", :force => true do |t|
    t.string "title",        :limit => 16, :default => "", :null => false
    t.string "abbreviation", :limit => 8
    t.string "code",         :limit => 8,  :default => "", :null => false
  end

  create_table "changesets", :force => true do |t|
    t.datetime "created_at",                                 :null => false
    t.integer  "changer_id",                 :default => 0,  :null => false
    t.string   "changer_type", :limit => 16, :default => "", :null => false
  end

  add_index "changesets", ["created_at"], :name => "index_changesets_on_created_at"

  create_table "dependency_alignment_terminations", :force => true do |t|
    t.integer "token_id",  :default => 0, :null => false
    t.integer "source_id", :default => 0, :null => false
  end

  add_index "dependency_alignment_terminations", ["source_id"], :name => "index_dependency_alignment_terminations_on_source_id"
  add_index "dependency_alignment_terminations", ["token_id"], :name => "index_dependency_alignment_terminations_on_token_id"

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

  create_table "import_sources", :force => true do |t|
    t.string   "tag",        :limit => 16, :default => "", :null => false
    t.text     "summary",                                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobs", :force => true do |t|
    t.string   "name",        :limit => 64,                               :default => "",    :null => false
    t.text     "parameters"
    t.integer  "user_id",                                                 :default => 0,     :null => false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.enum     "result",      :limit => [:successful, :failed, :aborted]
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "audited",                                                 :default => false, :null => false
    t.text     "log"
  end

  create_table "languages", :force => true do |t|
    t.string "iso_code", :limit => 3,  :default => "", :null => false
    t.string "name",     :limit => 32, :default => "", :null => false
  end

  add_index "languages", ["iso_code"], :name => "index_languages_on_iso_code", :unique => true

  create_table "lemmata", :force => true do |t|
    t.string   "lemma",         :limit => 64, :default => "",    :null => false
    t.string   "variant",       :limit => 16
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
    t.integer  "language_id",                 :default => 0,     :null => false
  end

  add_index "lemmata", ["language_id"], :name => "index_lemmata_on_language_id"
  add_index "lemmata", ["lemma"], :name => "index_lemmata_on_lemma"
  add_index "lemmata", ["variant"], :name => "index_lemmata_on_variant"

  create_table "notes", :force => true do |t|
    t.string   "notable_type",    :limit => 64, :default => "", :null => false
    t.integer  "notable_id",                    :default => 0,  :null => false
    t.string   "originator_type", :limit => 64, :default => "", :null => false
    t.integer  "originator_id",                 :default => 0,  :null => false
    t.text     "contents",                                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string "code",        :limit => 16, :default => "", :null => false
    t.string "description", :limit => 64, :default => "", :null => false
  end

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "semantic_attribute_values", :force => true do |t|
    t.integer  "semantic_attribute_id",               :default => 0,  :null => false
    t.string   "tag",                   :limit => 64, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "semantic_attribute_values", ["semantic_attribute_id"], :name => "index_semantic_attribute_values_on_semantic_attribute_id"

  create_table "semantic_attributes", :force => true do |t|
    t.string   "tag",        :limit => 64, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "semantic_tags", :force => true do |t|
    t.integer  "taggable_id",                               :default => 0,  :null => false
    t.string   "taggable_type",               :limit => 64, :default => "", :null => false
    t.integer  "semantic_attribute_value_id",               :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "semantic_tags", ["taggable_id"], :name => "index_semantic_tags_on_taggable_id"
  add_index "semantic_tags", ["taggable_type"], :name => "index_semantic_tags_on_taggable_type"

  create_table "sentences", :force => true do |t|
    t.integer  "sentence_number",       :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "annotated_by"
    t.datetime "annotated_at"
    t.integer  "reviewed_by"
    t.datetime "reviewed_at"
    t.boolean  "unalignable",           :default => false, :null => false
    t.boolean  "automatic_alignment",   :default => false
    t.integer  "sentence_alignment_id"
    t.integer  "source_division_id",    :default => 0,     :null => false
  end

  add_index "sentences", ["source_division_id", "sentence_number"], :name => "index_sentences_on_source_division_id_and_sentence_number"

  create_table "slash_edge_interpretations", :force => true do |t|
    t.string "tag",     :limit => 64,  :default => "", :null => false
    t.string "summary", :limit => 128, :default => "", :null => false
  end

  create_table "slash_edges", :force => true do |t|
    t.integer "slasher_id"
    t.integer "slashee_id"
    t.integer "slash_edge_interpretation_id", :default => 0, :null => false
  end

  add_index "slash_edges", ["slasher_id", "slashee_id"], :name => "index_slash_edges_on_slasher_and_slashee", :unique => true

  create_table "source_divisions", :force => true do |t|
    t.integer  "source_id",                                 :default => 0,  :null => false
    t.integer  "position",                                  :default => 0,  :null => false
    t.string   "title",                      :limit => 128, :default => "", :null => false
    t.string   "abbreviated_title",          :limit => 128, :default => "", :null => false
    t.string   "fields",                     :limit => 128, :default => "", :null => false
    t.integer  "aligned_source_division_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sources", :force => true do |t|
    t.string  "code",         :limit => 64, :default => "", :null => false
    t.text    "title"
    t.string  "abbreviation", :limit => 64, :default => "", :null => false
    t.integer "language_id",                :default => 0,  :null => false
    t.text    "tei_header",                                 :null => false
  end

  create_table "tokens", :force => true do |t|
    t.integer  "sentence_id",                                                                                                                     :default => 0,     :null => false
    t.integer  "verse"
    t.integer  "token_number",                                                                                                                    :default => 0,     :null => false
    t.string   "morphtag",                     :limit => 17
    t.string   "form",                         :limit => 64
    t.integer  "lemma_id"
    t.string   "relation",                     :limit => 20
    t.integer  "head_id"
    t.enum     "sort",                         :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end],              :default => :text, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_morphtag",              :limit => 17
    t.string   "source_lemma",                 :limit => 32
    t.text     "foreign_ids"
    t.boolean  "contraction",                                                                                                                     :default => false, :null => false
    t.enum     "nospacing",                    :limit => [:before, :after, :both]
    t.string   "presentation_form",            :limit => 128
    t.integer  "presentation_span"
    t.boolean  "emendation",                                                                                                                      :default => false, :null => false
    t.boolean  "abbreviation",                                                                                                                    :default => false, :null => false
    t.boolean  "capitalisation",                                                                                                                  :default => false, :null => false
    t.enum     "info_status",                  :limit => [:new, :acc, :acc_gen, :acc_disc, :acc_inf, :old, :no_info_status, :info_unannotatable]
    t.string   "empty_token_sort",             :limit => 1
    t.string   "contrast_group"
    t.integer  "antecedent_dist_in_words"
    t.integer  "antecedent_dist_in_sentences"
    t.integer  "token_alignment_id"
    t.boolean  "automatic_token_alignment",                                                                                                       :default => false
    t.integer  "dependency_alignment_id"
    t.integer  "antecedent_id"
  end

  add_index "tokens", ["contrast_group"], :name => "index_tokens_on_contrast_group"
  add_index "tokens", ["dependency_alignment_id"], :name => "index_tokens_on_dependency_alignment_id"
  add_index "tokens", ["head_id"], :name => "index_tokens_on_head_id"
  add_index "tokens", ["lemma_id"], :name => "index_tokens_on_lemma_id"
  add_index "tokens", ["morphtag"], :name => "index_tokens_on_morphtag"
  add_index "tokens", ["relation"], :name => "index_tokens_on_relation"
  add_index "tokens", ["sentence_id", "token_number"], :name => "index_tokens_on_sentence_id_and_token_number", :unique => true

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
    t.integer  "role_id",                                 :default => 1,         :null => false
    t.string   "state",                                   :default => "passive", :null => false
    t.datetime "deleted_at"
  end

end
