# Slash edge interpretations are the tags that label slash edges.
class Relation < ActiveRecord::Base
  attr_accessible :tag, :summary, :primary_relation, :secondary_relation
  change_logging

  has_many :slash_edges
  has_many :tokens

  validates_uniqueness_of :tag
  validates_presence_of :summary

  scope :primary, :conditions => { :primary_relation => true }, :order => 'tag'
  scope :secondary, :conditions => { :secondary_relation => true }, :order => 'tag'

  PREDICATIVE_RELATIONS = %w(xobj xadv)
  APPOSITIVE_RELATIONS = %w(apos)
  # FIXME: a misnomer
  NOMINAL_RELATIONS = %w(part obl sub obj narg voc)

  # Returns true if the relation is a predicative relation.
  def predicative?
    PREDICATIVE_RELATIONS.include?(tag)
  end

  # Returns true if the relation is a appositive relation.
  def appositive?
    APPOSITIVE_RELATIONS.include?(tag)
  end

  # Returns true if the relation is a nominal relation.
  def nominal?
    # FIXME: a misnomer
    NOMINAL_RELATIONS.include?(tag)
  end

  def to_s
    tag
  end

  def to_label
    tag
  end
end
