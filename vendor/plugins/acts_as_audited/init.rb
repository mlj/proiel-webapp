require 'acts_as_audited/audit'
require 'acts_as_audited'

ActiveRecord::Base.send :include, CollectiveIdea::Acts::Audited
