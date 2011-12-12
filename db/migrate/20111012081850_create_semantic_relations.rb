class CreateSemanticRelations < ActiveRecord::Migration
  def self.up
    create_table :semantic_relations do |t|
      t.integer "target_id"
      t.integer "controller_id"
      t.integer "semantic_relation_tag_id"
    end

     create_table :semantic_relation_tags do |t|
      t.string "tag"
      t.integer "semantic_relation_type_id"
    end

    create_table :semantic_relation_types do |t|
      t.string "tag"
    end

  end

  def self.down
    drop_table :semantic_relations
  end
end
