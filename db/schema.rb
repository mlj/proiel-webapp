# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160315182200) do

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id",    limit: 4
    t.string   "auditable_type",  limit: 255
    t.string   "action",          limit: 255
    t.text     "audited_changes", limit: 65535
    t.integer  "version",         limit: 4,     default: 0
    t.integer  "user_id",         limit: 4,     default: 0
    t.datetime "created_at",                                null: false
    t.string   "user_type",       limit: 8
    t.string   "username",        limit: 8
    t.string   "comment",         limit: 255
    t.string   "remote_address",  limit: 255
    t.integer  "associated_id",   limit: 4
    t.string   "associated_type", limit: 255
    t.string   "request_uuid",    limit: 255
  end

  add_index "audits", ["associated_id", "associated_type"], name: "associated_index", using: :btree
  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree

  create_table "dependency_alignment_terms", force: :cascade do |t|
    t.integer "token_id",  limit: 4, default: 0, null: false
    t.integer "source_id", limit: 4, default: 0, null: false
  end

  add_index "dependency_alignment_terms", ["source_id"], name: "idx_depalterms_source_id", using: :btree
  add_index "dependency_alignment_terms", ["token_id"], name: "idx_depaliterms_token_id", using: :btree

  create_table "import_sources", force: :cascade do |t|
    t.string   "tag",        limit: 16,    default: "", null: false
    t.text     "summary",    limit: 65535,              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inflections", force: :cascade do |t|
    t.string   "language_tag",       limit: 3,  default: "",    null: false
    t.string   "form",               limit: 64
    t.string   "lemma",              limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "manual_rule",                   default: false, null: false
    t.string   "morphology_tag",     limit: 11, default: "",    null: false
    t.string   "part_of_speech_tag", limit: 2,                  null: false
  end

  add_index "inflections", ["language_tag", "form", "morphology_tag", "lemma", "part_of_speech_tag"], name: "idx_infl_unique", unique: true, using: :btree
  add_index "inflections", ["language_tag", "form"], name: "idx_inflections_lf", using: :btree
  add_index "inflections", ["morphology_tag"], name: "idx_inflections_m", using: :btree

  create_table "lemmata", force: :cascade do |t|
    t.string   "lemma",              limit: 64,    default: "", null: false
    t.integer  "variant",            limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gloss",              limit: 64
    t.text     "foreign_ids",        limit: 65535
    t.string   "language_tag",       limit: 3,     default: "", null: false
    t.string   "part_of_speech_tag", limit: 2,     default: "", null: false
  end

  add_index "lemmata", ["language_tag"], name: "index_lemmata_on_language_id", using: :btree
  add_index "lemmata", ["lemma", "part_of_speech_tag", "variant", "language_tag"], name: "lemmata_uniqueness", unique: true, using: :btree
  add_index "lemmata", ["lemma"], name: "index_lemmata_on_lemma", using: :btree
  add_index "lemmata", ["variant"], name: "index_lemmata_on_variant", using: :btree

  create_table "notes", force: :cascade do |t|
    t.string   "notable_type",    limit: 64,    default: "", null: false
    t.integer  "notable_id",      limit: 4,     default: 0,  null: false
    t.string   "originator_type", limit: 64,    default: "", null: false
    t.integer  "originator_id",   limit: 4,     default: 0,  null: false
    t.text     "contents",        limit: 65535,              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["notable_id", "notable_type"], name: "idx_notes_notable", using: :btree

  create_table "semantic_attribute_values", force: :cascade do |t|
    t.integer  "semantic_attribute_id", limit: 4,  default: 0,  null: false
    t.string   "tag",                   limit: 64, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "semantic_attribute_values", ["semantic_attribute_id"], name: "idx_semattrvalues_semattr_id", using: :btree

  create_table "semantic_attributes", force: :cascade do |t|
    t.string   "tag",        limit: 64, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "semantic_relation_tags", force: :cascade do |t|
    t.string  "tag",                       limit: 255
    t.integer "semantic_relation_type_id", limit: 4
  end

  create_table "semantic_relation_types", force: :cascade do |t|
    t.string "tag", limit: 255
  end

  create_table "semantic_relations", force: :cascade do |t|
    t.integer "target_id",                limit: 4
    t.integer "controller_id",            limit: 4
    t.integer "semantic_relation_tag_id", limit: 4
  end

  create_table "semantic_tags", force: :cascade do |t|
    t.integer  "taggable_id",                 limit: 4,  default: 0,  null: false
    t.string   "taggable_type",               limit: 64, default: "", null: false
    t.integer  "semantic_attribute_value_id", limit: 4,  default: 0,  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "semantic_tags", ["taggable_id"], name: "idx_semtags_taggable_id", using: :btree
  add_index "semantic_tags", ["taggable_type"], name: "idx_semtags_taggable_type", using: :btree

  create_table "sentences", force: :cascade do |t|
    t.integer  "sentence_number",       limit: 4,  default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "annotated_by",          limit: 4
    t.datetime "annotated_at"
    t.integer  "reviewed_by",           limit: 4
    t.datetime "reviewed_at"
    t.boolean  "unalignable",                      default: false, null: false
    t.boolean  "automatic_alignment",              default: false
    t.integer  "sentence_alignment_id", limit: 4
    t.integer  "source_division_id",    limit: 4,  default: 0,     null: false
    t.integer  "assigned_to",           limit: 4
    t.string   "presentation_before",   limit: 64
    t.string   "presentation_after",    limit: 64
    t.string   "status_tag",            limit: 12,                 null: false
  end

  add_index "sentences", ["assigned_to"], name: "index_sentences_on_assigned_to", using: :btree
  add_index "sentences", ["source_division_id", "sentence_number"], name: "idx_sentences_sdid_snu", using: :btree
  add_index "sentences", ["status_tag"], name: "index_tokens_on_status_tag", using: :btree

  create_table "slash_edges", force: :cascade do |t|
    t.integer "slasher_id",   limit: 4
    t.integer "slashee_id",   limit: 4
    t.string  "relation_tag", limit: 8, default: "0", null: false
  end

  add_index "slash_edges", ["slasher_id", "slashee_id"], name: "idx_slash_edges_ser_see", unique: true, using: :btree

  create_table "source_divisions", force: :cascade do |t|
    t.integer  "source_id",                       limit: 4,     default: 0, null: false
    t.integer  "position",                        limit: 4,     default: 0, null: false
    t.string   "title",                           limit: 128
    t.integer  "aligned_source_division_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "presentation_before",             limit: 65535
    t.text     "presentation_after",              limit: 65535
    t.string   "cached_citation",                 limit: 128
    t.string   "cached_status_tag",               limit: 12
    t.boolean  "cached_has_discourse_annotation"
  end

  add_index "source_divisions", ["source_id"], name: "source_divisions_source_id", using: :btree

  create_table "sources", force: :cascade do |t|
    t.string "title",               limit: 128,   default: "", null: false
    t.string "citation_part",       limit: 64,    default: "", null: false
    t.string "language_tag",        limit: 3,     default: "", null: false
    t.text   "author",              limit: 255
    t.string "code",                limit: 32,                 null: false
    t.text   "additional_metadata", limit: 65535
  end

  create_table "tokens", force: :cascade do |t|
    t.integer  "sentence_id",               limit: 4,     default: 0,     null: false
    t.integer  "token_number",              limit: 4,     default: 0,     null: false
    t.string   "form",                      limit: 64
    t.integer  "lemma_id",                  limit: 4
    t.integer  "head_id",                   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_morphology_tag",     limit: 11
    t.string   "source_lemma",              limit: 32
    t.text     "foreign_ids",               limit: 65535
    t.string   "information_status_tag",    limit: 20
    t.string   "empty_token_sort",          limit: 1
    t.string   "contrast_group",            limit: 255
    t.integer  "token_alignment_id",        limit: 4
    t.boolean  "automatic_token_alignment",               default: false
    t.integer  "dependency_alignment_id",   limit: 4
    t.integer  "antecedent_id",             limit: 4
    t.string   "relation_tag",              limit: 8
    t.string   "morphology_tag",            limit: 11
    t.string   "citation_part",             limit: 64
    t.string   "presentation_before",       limit: 32
    t.string   "presentation_after",        limit: 32
    t.integer  "mlj_binder_id",             limit: 4
    t.string   "mlj_logocentre",            limit: 255
    t.text     "mlj_old",                   limit: 65535
    t.integer  "mlj_controller_id",         limit: 4
  end

  add_index "tokens", ["antecedent_id"], name: "index_tokens_on_antecedent_id", using: :btree
  add_index "tokens", ["contrast_group"], name: "index_tokens_on_contrast_group", using: :btree
  add_index "tokens", ["dependency_alignment_id"], name: "idx_tokens_depalid", using: :btree
  add_index "tokens", ["form"], name: "index_tokens_on_form", using: :btree
  add_index "tokens", ["head_id"], name: "index_tokens_on_head_id", using: :btree
  add_index "tokens", ["lemma_id"], name: "index_tokens_on_lemma_id", using: :btree
  add_index "tokens", ["morphology_tag"], name: "index_tokens_on_morphology_id", using: :btree
  add_index "tokens", ["relation_tag"], name: "index_tokens_on_relation_id", using: :btree
  add_index "tokens", ["sentence_id", "token_number"], name: "idx_tokens_sid_tnur", unique: true, using: :btree
  add_index "tokens", ["token_alignment_id"], name: "idx_tokens_tokalid", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "login",                  limit: 255, default: "", null: false
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 40,  default: "", null: false
    t.string   "password_salt",          limit: 255, default: "", null: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.datetime "confirmed_at"
    t.string   "last_name",              limit: 60,  default: "", null: false
    t.string   "first_name",             limit: 60,  default: "", null: false
    t.string   "preferences",            limit: 255
    t.string   "confirmation_token",     limit: 20
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token",   limit: 20
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.integer  "failed_attempts",        limit: 4,   default: 0
    t.string   "unlock_token",           limit: 20
    t.datetime "locked_at"
    t.string   "role",                   limit: 255, default: "", null: false
    t.datetime "reset_password_sent_at"
  end

  add_index "users", ["confirmation_token"], name: "idx_users_conf_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "idx_users_reset_pw_token", unique: true, using: :btree

end
