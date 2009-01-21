class AddSemanticTagIndices < ActiveRecord::Migration
  def self.up 
    add_index :semantic_attribute_values, :semantic_attribute_id
    add_index :semantic_tags, :taggable_id
    add_index :semantic_tags, :taggable_type
  end

  def self.down
    remove_index :semantic_tags, :taggable_type
    remove_index :semantic_tags, :taggable_id
    remove_index :semantic_attribute_values, :semantic_attribute_id
  end
end
