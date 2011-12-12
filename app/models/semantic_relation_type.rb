class SemanticRelationType < ActiveRecord::Base
  has_many :semantic_relation_tags

  validates_presence_of :tag
  validates_uniqueness_of :tag
end
