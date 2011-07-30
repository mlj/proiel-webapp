class RemoveAnimacy < ActiveRecord::Migration
  def self.up
    execute("INSERT INTO semantic_attributes(tag, created_at, updated_at) VALUES('MASCULINE_ANIMACY', now(), now())")
    execute("INSERT INTO semantic_attribute_values(semantic_attribute_id, tag, created_at, updated_at) VALUES ((SELECT id FROM semantic_attributes WHERE tag = 'MASCULINE_ANIMACY'), 'animate', now(), now())")
    execute("INSERT INTO semantic_attribute_values(semantic_attribute_id, tag, created_at, updated_at) VALUES ((SELECT id FROM semantic_attributes WHERE tag = 'MASCULINE_ANIMACY'), 'inanimate', now(), now())")
    anim = SemanticAttributeValue.find_by_tag('animate').id
    inanim = SemanticAttributeValue.find_by_tag('inanimate').id

    say_with_time("Adding semantic tags for animacy to tokens")

    Token.find(:all, :conditions => "morphology like '________a%'").each do |t|
      SemanticTag.create(:semantic_attribute_value_id => anim, :taggable_type => "Token", :taggable_id => t.id)
    end

    say_with_time("Adding semantic tags for inanimacy to tokens")

    Token.find(:all, :conditions => "morphology like '________i%'").each do |t|
      SemanticTag.create(:semantic_attribute_value_id => anim, :taggable_type => "Token", :taggable_id => t.id)
    end

    say_with_time("Removing animacy field from tokens")

    execute("UPDATE tokens SET morphology = CONCAT(SUBSTRING(morphology, 1, 8), SUBSTRING(morphology, 10, 2))")
    execute("UPDATE tokens SET source_morphology = CONCAT(SUBSTRING(source_morphology, 1, 8), SUBSTRING(source_morphology, 10, 2))")

    say_with_time("Removing animacy field from inflections")

    execute("DROP index idx_inflections_lfml ON inflections")
    execute("UPDATE inflections SET morphology = CONCAT(SUBSTRING(morphology, 1, 8), SUBSTRING(morphology, 10, 2))")
    execute("CREATE TEMPORARY TABLE tmp SELECT id FROM inflections GROUP BY language, form, lemma, morphology HAVING count(*) > 1")
    execute("DELETE FROM inflections WHERE id IN (SELECT * FROM tmp);")

    add_index "inflections", ["language", "form", "morphology", "lemma"], :name => "idx_inflections_lfml", :unique => true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
