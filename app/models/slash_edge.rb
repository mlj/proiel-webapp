# Slash edges are directed, labelled edges in the depedency
# graph. They are inteded to be used as indicators of various forms
# of coindexing. The `slasher' is generally the element that has a `gap',
# and the `slashee' is the element that would fill the `gap'.
class SlashEdge < ActiveRecord::Base
  belongs_to :slasher, :class_name => 'Token', :foreign_key => 'slasher_id'
  belongs_to :slashee, :class_name => 'Token', :foreign_key => 'slashee_id'
  belongs_to :slash_edge_interpretation

  validates_uniqueness_of :slasher_id, :scope => :slashee_id,
    :message => 'Slash edge already exists in dependency structure'
  validates_presence_of :slash_edge_interpretation

  acts_as_audited
end
