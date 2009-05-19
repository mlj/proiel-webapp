# Slash edge interpretations are the tags that label slash edges.
class Relation < ActiveRecord::Base
  has_many :slash_edges
  has_many :tokens

  validates_uniqueness_of :tag
  validates_presence_of :summary

  named_scope :primary, :conditions => { :primary_relation => true }, :order => 'tag'
  named_scope :secondary, :conditions => { :secondary_relation => true }, :order => 'tag'

  acts_as_audited
end
