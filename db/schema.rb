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
    t.integer "auditable_id"
    t.string "auditable_type"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.integer "user_id", default: 0
    t.datetime "created_at", null: false
    t.string "user_type", limit: 8
    t.string "username", limit: 8
    t.string "comment"
    t.string "remote_address"
    t.integer "associated_id"
    t.string "associated_type"
    t.string "request_uuid"
    t.index ["associated_id", "associated_type"], name: "associated_index"
    t.index ["auditable_id", "auditable_type"], name: "auditable_index"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
  end

  create_table "dependency_alignment_terms", id: :integer, force: :cascade do |t|
    t.integer "token_id", default: 0, null: false
    t.integer "source_id", default: 0, null: false
    t.index ["source_id"], name: "idx_depalterms_source_id"
    t.index ["token_id"], name: "idx_depaliterms_token_id"
  end

  create_table "import_sources", id: :integer, force: :cascade do |t|
    t.string "tag", limit: 16, default: "", null: false
    t.text "summary", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "inflections", id: :integer, force: :cascade do |t|
    t.string "language_tag", limit: 3, default: "", null: false
    t.string "form", limit: 64
    t.string "lemma", limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "manual_rule", default: false, null: false
    t.string "morphology_tag", limit: 11, default: "", null: false
    t.string "part_of_speech_tag", limit: 2, null: false
    t.index ["language_tag", "form", "morphology_tag", "lemma", "part_of_speech_tag"], name: "idx_infl_unique", unique: true
    t.index ["language_tag", "form"], name: "idx_inflections_lf"
    t.index ["morphology_tag"], name: "idx_inflections_m"
  end

  create_table "lemmata", id: :integer, force: :cascade do |t|
    t.string "lemma", limit: 64, default: "", null: false
    t.integer "variant", limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "gloss", limit: 64
    t.text "foreign_ids"
    t.string "language_tag", limit: 3, default: "", null: false
    t.string "part_of_speech_tag", limit: 2, default: "", null: false
    t.index ["language_tag"], name: "index_lemmata_on_language_id"
    t.index ["lemma", "part_of_speech_tag", "variant", "language_tag"], name: "lemmata_uniqueness", unique: true
    t.index ["lemma"], name: "index_lemmata_on_lemma"
    t.index ["variant"], name: "index_lemmata_on_variant"
  end

  create_table "notes", id: :integer, force: :cascade do |t|
    t.string "notable_type", limit: 64, default: "", null: false
    t.integer "notable_id", default: 0, null: false
    t.string "originator_type", limit: 64, default: "", null: false
    t.integer "originator_id", default: 0, null: false
    t.text "contents", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["notable_id", "notable_type"], name: "idx_notes_notable"
  end

  create_table "semantic_attribute_values", id: :integer, force: :cascade do |t|
    t.integer "semantic_attribute_id", default: 0, null: false
    t.string "tag", limit: 64, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["semantic_attribute_id"], name: "idx_semattrvalues_semattr_id"
  end

  create_table "semantic_attributes", id: :integer, force: :cascade do |t|
    t.string "tag", limit: 64, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "semantic_relation_tags", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "tag"
    t.integer "semantic_relation_type_id"
  end

  create_table "semantic_relation_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "tag"
  end

  create_table "semantic_relations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer "target_id"
    t.integer "controller_id"
    t.integer "semantic_relation_tag_id"
  end

  create_table "semantic_tags", id: :integer, force: :cascade do |t|
    t.integer "taggable_id", default: 0, null: false
    t.string "taggable_type", limit: 64, default: "", null: false
    t.integer "semantic_attribute_value_id", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["taggable_id"], name: "idx_semtags_taggable_id"
    t.index ["taggable_type"], name: "idx_semtags_taggable_type"
  end

  create_table "sentences", id: :integer, force: :cascade do |t|
    t.integer "sentence_number", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "annotated_by"
    t.datetime "annotated_at"
    t.integer "reviewed_by"
    t.datetime "reviewed_at"
    t.boolean "unalignable", default: false, null: false
    t.boolean "automatic_alignment", default: false
    t.integer "sentence_alignment_id"
    t.integer "source_division_id", default: 0, null: false
    t.integer "assigned_to"
    t.string "presentation_before", limit: 64
    t.string "presentation_after", limit: 64
    t.string "status_tag", limit: 12, null: false
    t.index ["assigned_to"], name: "index_sentences_on_assigned_to"
    t.index ["source_division_id", "sentence_number"], name: "idx_sentences_sdid_snu"
    t.index ["status_tag"], name: "index_tokens_on_status_tag"
  end

  create_table "slash_edges", id: :integer, force: :cascade do |t|
    t.integer "slasher_id"
    t.integer "slashee_id"
    t.string "relation_tag", limit: 8, default: "0", null: false
    t.index ["slasher_id", "slashee_id"], name: "idx_slash_edges_ser_see", unique: true
  end

  create_table "source_divisions", id: :integer, force: :cascade do |t|
    t.integer "source_id", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.string "title", limit: 128
    t.integer "aligned_source_division_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "presentation_before"
    t.text "presentation_after"
    t.string "cached_citation", limit: 128
    t.string "cached_status_tag", limit: 12
    t.boolean "cached_has_discourse_annotation"
    t.index ["source_id"], name: "source_divisions_source_id"
  end

  create_table "sources", id: :integer, force: :cascade do |t|
    t.string "title", limit: 128, default: "", null: false
    t.string "citation_part", limit: 64, default: "", null: false
    t.string "language_tag", limit: 3, default: "", null: false
    t.text "author", limit: 255
    t.string "code", limit: 32, null: false
    t.text "additional_metadata"
  end

  create_table "tokens", id: :integer, force: :cascade, comment: "InnoDB free: 31744 kB" do |t|
    t.integer "sentence_id", default: 0, null: false
    t.integer "token_number", default: 0, null: false
    t.string "form", limit: 64
    t.integer "lemma_id"
    t.integer "head_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "source_morphology_tag", limit: 11
    t.string "source_lemma", limit: 32
    t.text "foreign_ids"
    t.string "information_status_tag", limit: 20
    t.string "empty_token_sort", limit: 1
    t.string "contrast_group"
    t.integer "token_alignment_id"
    t.boolean "automatic_token_alignment", default: false
    t.integer "dependency_alignment_id"
    t.integer "antecedent_id"
    t.string "relation_tag", limit: 8
    t.string "morphology_tag", limit: 11
    t.string "citation_part", limit: 64
    t.string "presentation_before", limit: 32
    t.string "presentation_after", limit: 32
    t.integer "mlj_binder_id"
    t.string "mlj_logocentre"
    t.text "mlj_old"
    t.integer "mlj_controller_id"
    t.index ["antecedent_id"], name: "index_tokens_on_antecedent_id"
    t.index ["contrast_group"], name: "index_tokens_on_contrast_group"
    t.index ["dependency_alignment_id"], name: "idx_tokens_depalid"
    t.index ["form"], name: "index_tokens_on_form"
    t.index ["head_id"], name: "index_tokens_on_head_id"
    t.index ["lemma_id"], name: "index_tokens_on_lemma_id"
    t.index ["morphology_tag"], name: "index_tokens_on_morphology_id"
    t.index ["relation_tag"], name: "index_tokens_on_relation_id"
    t.index ["sentence_id", "token_number"], name: "idx_tokens_sid_tnur", unique: true
    t.index ["token_alignment_id"], name: "idx_tokens_tokalid"
  end

  create_table "users", id: :integer, force: :cascade do |t|
    t.string "login", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", limit: 40, default: "", null: false
    t.string "password_salt", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.string "last_name", limit: 60, default: "", null: false
    t.string "first_name", limit: 60, default: "", null: false
    t.string "preferences"
    t.string "confirmation_token", limit: 20
    t.datetime "confirmation_sent_at"
    t.string "reset_password_token", limit: 20
    t.datetime "remember_created_at"
    t.integer "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token", limit: 20
    t.datetime "locked_at"
    t.string "role", default: "", null: false
    t.datetime "reset_password_sent_at"
    t.index ["confirmation_token"], name: "idx_users_conf_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "idx_users_reset_pw_token", unique: true
  end

end
