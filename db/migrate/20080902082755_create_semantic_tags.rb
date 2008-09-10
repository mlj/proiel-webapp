class CreateSemanticTags < ActiveRecord::Migration
  def self.up
    create_table :semantic_attributes do |t|
      t.string  :tag,     :limit => 64,  :null => false

      t.timestamps
    end

    create_table :semantic_attribute_values do |t|
      t.integer :semantic_attribute_id, :null => false
      t.string  :tag,     :limit => 64, :null => false

      t.timestamps
    end

    create_table :semantic_tags do |t|
      t.integer :taggable_id,                 :null => false
      t.string  :taggable_type, :limit => 64, :null => false
      t.integer :semantic_attribute_value_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :semantic_tags
    drop_table :semantic_tag_attribute_values
    drop_table :semantic_tag_attributes
  end
end
