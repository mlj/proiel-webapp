class DependencyAlignmentTerm < ActiveRecord::Base
  belongs_to :token
  belongs_to :source

  acts_as_audited
end
