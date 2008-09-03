class SemanticAttributeValue < ActiveRecord::Base
  belongs_to :semantic_attribute
  has_many :semantic_tags

  validates_presence_of :tag
  validates_uniqueness_of :tag, :scope => :semantic_attribute
end
