class ShortenTableAndIndexNames < ActiveRecord::Migration
  def self.up
    rename_index :dependency_alignment_terminations, "index_dependency_alignment_terminations_on_source_id", "idx_depalterms_source_id"
    rename_index :dependency_alignment_terminations, "index_dependency_alignment_terminations_on_token_id", "idx_depaliterms_token_id"
    rename_index :inflections, "index_inflections_on_language_and_form_and_morphology_and_lemma", "idx_inflections_lfml"
    rename_index :inflections, "index_inflections_on_language_id_and_form", "idx_inflections_lf"
    rename_index :inflections, "index_inflections_on_morphology_id", "idx_inflections_m"
    rename_index :notes, "index_notes_on_notable_id_and_notable_type", "idx_notes_notable"
    rename_index :semantic_attribute_values, "index_semantic_attribute_values_on_semantic_attribute_id", "idx_semattrvalues_semattr_id"
    rename_index :semantic_tags, "index_semantic_tags_on_taggable_id", "idx_semtags_taggable_id"
    rename_index :semantic_tags, "index_semantic_tags_on_taggable_type", "idx_semtags_taggable_type"
    rename_index :sentences, "index_sentences_on_source_division_id_and_sentence_number", "idx_sentences_sdid_snu"
    rename_index :slash_edges, "index_slash_edges_on_slasher_and_slashee", "idx_slash_edges_ser_see"
    rename_index :tokens, "index_tokens_on_dependency_alignment_id", "idx_tokens_depalid"
    rename_index :tokens, "index_tokens_on_sentence_id_and_token_number", "idx_tokens_sid_tnur"
    rename_index :tokens, "index_tokens_on_token_alignment_id", "idx_tokens_tokalid"
    rename_index :users, "index_users_on_confirmation_token", "idx_users_conf_token"
    rename_index :users, "index_users_on_reset_password_token", "idx_users_reset_pw_token"

    rename_table :dependency_alignment_terminations, :dependency_alignment_terms
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
