class DependencyAlignmentTermination < ActiveRecord::Base
  belongs_to :token
  belongs_to :source
end
