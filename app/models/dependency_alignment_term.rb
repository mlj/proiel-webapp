class DependencyAlignmentTerm < ActiveRecord::Base
  belongs_to :token
  belongs_to :source

  change_logging
end
