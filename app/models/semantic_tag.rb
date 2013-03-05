class SemanticTag < ActiveRecord::Base
  belongs_to :semantic_attribute_value
  belongs_to :taggable, :polymorphic => true

  validates_presence_of :taggable
  validates_presence_of :semantic_attribute_value

  # Returns the semantic attribute for this tag.
  def semantic_attribute
    semantic_attribute_value.semantic_attribute
  end
end
