class SemanticRelationTag < ActiveRecord::Base
  belongs_to :semantic_relation_type
  has_many :semantic_relations

  validates_presence_of :tag
  validates_uniqueness_of :tag
end
