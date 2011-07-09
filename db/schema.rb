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

ActiveRecord::Schema.define(:version => 20110220182909) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.string   "action"
    t.text     "changes"
    t.integer  "version",                     :default => 0
    t.integer  "user_id",                     :default => 0
    t.datetime "created_at",                                 :null => false
    t.string   "user_type",      :limit => 8
    t.string   "username",       :limit => 8
  end

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"

  create_table "dependency_alignment_terms", :force => true do |t|
    t.integer "token_id",  :default => 0, :null => false
    t.integer "source_id", :default => 0, :null => false
  end

  add_index "dependency_alignment_terms", ["source_id"], :name => "idx_depalterms_source_id"
  add_index "dependency_alignment_terms", ["token_id"], :name => "idx_depaliterms_token_id"

  create_table "import_sources", :force => true do |t|
    t.string   "tag",        :limit => 16, :default => "", :null => false
    t.text     "summary",                                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inflections", :force => true do |t|
    t.string   "language",    :limit => 3,  :default => "",    :null => false
    t.string   "form",        :limit => 64
    t.string   "lemma",       :limit => 64
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "manual_rule",               :default => false, :null => false
    t.string   "morphology",  :limit => 11, :default => "",    :null => false
  end

  add_index "inflections", ["language", "form", "morphology", "lemma"], :name => "idx_inflections_lfml", :unique => true
  add_index "inflections", ["language", "form"], :name => "idx_inflections_lf"
  add_index "inflections", ["morphology"], :name => "idx_inflections_m"

  create_table "lemmata", :force => true do |t|
    t.string   "lemma",          :limit => 64, :default => "", :null => false
    t.integer  "variant",        :limit => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short_gloss",    :limit => 64
    t.text     "full_gloss"
    t.string   "sort_key",       :limit => 16
    t.text     "foreign_ids"
    t.boolean  "conjecture"
    t.boolean  "unclear"
    t.boolean  "reconstructed"
    t.boolean  "nonexistant"
    t.boolean  "inflected"
    t.string   "language",       :limit => 3,  :default => "", :null => false
    t.string   "part_of_speech", :limit => 2,  :default => "", :null => false
  end

  add_index "lemmata", ["language"], :name => "index_lemmata_on_language_id"
  add_index "lemmata", ["lemma", "part_of_speech", "variant", "language"], :name => "lemmata_uniqueness", :unique => true
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

  add_index "notes", ["notable_id", "notable_type"], :name => "idx_notes_notable"

  create_table "relation_equivalences", :id => false, :force => true do |t|
    t.integer "subrelation_id",   :null => false
    t.integer "superrelation_id", :null => false
  end

  create_table "relations", :force => true do |t|
    t.string  "tag",                :limit => 64,  :default => "",    :null => false
    t.string  "summary",            :limit => 128, :default => "",    :null => false
    t.boolean "primary_relation",                  :default => false, :null => false
    t.boolean "secondary_relation",                :default => false, :null => false
  end

  create_table "roles", :force => true do |t|
    t.string "code",        :limit => 16, :default => "", :null => false
    t.string "description", :limit => 64, :default => "", :null => false
  end

  create_table "semantic_attribute_values", :force => true do |t|
    t.integer  "semantic_attribute_id",               :default => 0,  :null => false
    t.string   "tag",                   :limit => 64, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "semantic_attribute_values", ["semantic_attribute_id"], :name => "idx_semattrvalues_semattr_id"

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

  add_index "semantic_tags", ["taggable_id"], :name => "idx_semtags_taggable_id"
  add_index "semantic_tags", ["taggable_type"], :name => "idx_semtags_taggable_type"

  create_table "sentences", :force => true do |t|
    t.integer  "sentence_number",                      :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "annotated_by"
    t.datetime "annotated_at"
    t.integer  "reviewed_by"
    t.datetime "reviewed_at"
    t.boolean  "unalignable",                          :default => false, :null => false
    t.boolean  "automatic_alignment",                  :default => false
    t.integer  "sentence_alignment_id"
    t.integer  "source_division_id",                   :default => 0,     :null => false
    t.text     "presentation",                                            :null => false
    t.string   "reference_fields",      :limit => 128, :default => "",    :null => false
    t.integer  "assigned_to"
  end

  add_index "sentences", ["assigned_to"], :name => "index_sentences_on_assigned_to"
  add_index "sentences", ["source_division_id", "sentence_number"], :name => "idx_sentences_sdid_snu"

  create_table "slash_edges", :force => true do |t|
    t.integer "slasher_id"
    t.integer "slashee_id"
    t.integer "relation_id", :default => 0, :null => false
  end

  add_index "slash_edges", ["slasher_id", "slashee_id"], :name => "idx_slash_edges_ser_see", :unique => true

  create_table "source_divisions", :force => true do |t|
    t.integer  "source_id",                                 :default => 0,  :null => false
    t.integer  "position",                                  :default => 0,  :null => false
    t.string   "title",                      :limit => 128
    t.string   "abbreviated_title",          :limit => 128, :default => "", :null => false
    t.integer  "aligned_source_division_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "presentation",                                              :null => false
    t.string   "reference_fields",           :limit => 128, :default => "", :null => false
  end

  create_table "sources", :force => true do |t|
    t.string "code",               :limit => 64,  :default => "", :null => false
    t.string "title",              :limit => 128, :default => "", :null => false
    t.string "abbreviation",       :limit => 64,  :default => "", :null => false
    t.string "language",           :limit => 3,   :default => "", :null => false
    t.text   "tei_header",                                        :null => false
    t.string "tracked_references", :limit => 128, :default => "", :null => false
    t.string "reference_fields",   :limit => 128, :default => "", :null => false
    t.string "reference_format",   :limit => 256, :default => "", :null => false
  end

  create_table "tokens", :force => true do |t|
    t.integer  "sentence_id",                              :default => 0,     :null => false
    t.integer  "verse"
    t.integer  "token_number",                             :default => 0,     :null => false
    t.string   "form",                      :limit => 64
    t.integer  "lemma_id"
    t.integer  "head_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_morphology",         :limit => 17
    t.string   "source_lemma",              :limit => 32
    t.text     "foreign_ids"
    t.string   "info_status",               :limit => 20
    t.string   "empty_token_sort",          :limit => 1
    t.string   "contrast_group"
    t.integer  "token_alignment_id"
    t.boolean  "automatic_token_alignment",                :default => false
    t.integer  "dependency_alignment_id"
    t.integer  "antecedent_id"
    t.integer  "relation_id"
    t.string   "morphology",                :limit => 11
    t.string   "reference_fields",          :limit => 128, :default => "",    :null => false
  end

  add_index "tokens", ["antecedent_id"], :name => "index_tokens_on_antecedent_id"
  add_index "tokens", ["contrast_group"], :name => "index_tokens_on_contrast_group"
  add_index "tokens", ["dependency_alignment_id"], :name => "idx_tokens_depalid"
  add_index "tokens", ["form"], :name => "index_tokens_on_form"
  add_index "tokens", ["head_id"], :name => "index_tokens_on_head_id"
  add_index "tokens", ["lemma_id"], :name => "index_tokens_on_lemma_id"
  add_index "tokens", ["morphology"], :name => "index_tokens_on_morphology_id"
  add_index "tokens", ["relation_id"], :name => "index_tokens_on_relation_id"
  add_index "tokens", ["sentence_id", "token_number"], :name => "idx_tokens_sid_tnur", :unique => true
  add_index "tokens", ["token_alignment_id"], :name => "idx_tokens_tokalid"

  create_table "users", :force => true do |t|
    t.string   "login",                              :default => "", :null => false
    t.string   "email",                              :default => "", :null => false
    t.string   "encrypted_password",   :limit => 40, :default => "", :null => false
    t.string   "password_salt",                      :default => "", :null => false
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.datetime "confirmed_at"
    t.string   "last_name",            :limit => 60, :default => "", :null => false
    t.string   "first_name",           :limit => 60, :default => "", :null => false
    t.string   "preferences"
    t.integer  "role_id",                            :default => 1,  :null => false
    t.string   "confirmation_token",   :limit => 20
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token", :limit => 20
    t.string   "remember_token",       :limit => 20
    t.datetime "remember_created_at"
    t.integer  "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                    :default => 0
    t.string   "unlock_token",         :limit => 20
    t.datetime "locked_at"
  end

  add_index "users", ["confirmation_token"], :name => "idx_users_conf_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "idx_users_reset_pw_token", :unique => true

end
