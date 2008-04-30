# Slash edges are directed, unlabelled edges in the depedency 
# graph. They are inteded to be used as indicators of various forms
# of coindexing. The `slasher' is generally the element that has a `gap'
# something, and the `slashee' is the element that would fill the `gap'.
class SlashEdge < ActiveRecord::Base
  belongs_to :slasher, :class_name => 'Token', :foreign_key => 'slasher_id'
  belongs_to :slashee, :class_name => 'Token', :foreign_key => 'slashee_id'

  validates_uniqueness_of :slasher_id, :scope => :slashee_id,
    :message => 'Slash edge already exists in dependency structure'

  acts_as_audited

  # Creates a new edge.
  def self.add_edge(slasher_id, slashee_id)
    SlashEdge.create(:slasher_id => slasher_id, :slashee_id => slashee_id)
  end
end
