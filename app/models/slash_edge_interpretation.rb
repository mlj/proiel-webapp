# Slash edge interpretations are the tags that label slash edges.
class SlashEdgeInterpretation < ActiveRecord::Base
  has_many :slash_edges

  validates_uniqueness_of :tag
  validates_presence_of :summary
  validates_inclusion_of :tag, :allow_nil => false, :in => PROIEL::SECONDARY_RELATION_TAGS

  acts_as_audited
end
