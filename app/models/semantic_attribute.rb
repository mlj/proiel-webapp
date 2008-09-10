class SemanticAttribute < ActiveRecord::Base
  has_many :semantic_attribute_values

  validates_presence_of :tag
  validates_uniqueness_of :tag
end
