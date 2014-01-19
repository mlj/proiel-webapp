class SemanticAttribute < ActiveRecord::Base
  attr_accessible :tag

  has_many :semantic_attribute_values

  validates_presence_of :tag
  validates_uniqueness_of :tag

  def add_value!(value)
    semantic_attribute_values.create! tag: value
  end
end
