class SemanticAttributeValue < ActiveRecord::Base
  attr_accessible :tag

  belongs_to :semantic_attribute
  has_many :semantic_tags

  validates_presence_of :tag
  validates_uniqueness_of :tag, :scope => :semantic_attribute_id
end
