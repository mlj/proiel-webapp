Audited::Adapters::ActiveRecord::Audit.class_eval do
  attr_accessible :action, :audited_changes, :comment
end
