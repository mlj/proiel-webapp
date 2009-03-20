require 'set'

# Audit saves the changes to ActiveRecord models.  It has the following attributes:
#
# * <tt>auditable</tt>: the ActiveRecord model that was changed
# * <tt>user</tt>: the user that performed the change; a string or an ActiveRecord model
# * <tt>action</tt>: one of create, update, or delete
# * <tt>changes</tt>: a serialized hash of all the changes
# * <tt>created_at</tt>: Time that the change was performed
#
class Audit < ActiveRecord::Base
  belongs_to :auditable, :polymorphic => true
  belongs_to :user
  stampable :creator_attribute => :user_id
  
  before_create :set_version_number
  
  serialize :changes
  
  cattr_accessor :audited_classes
  self.audited_classes = Set.new
  
  def revision
    attributes = self.class.reconstruct_attributes(ancestors).merge({:version => version})
    clazz = auditable_type.constantize
    returning clazz.find_by_id(auditable_id) || clazz.new do |m|
      m.attributes = attributes
    end
  end
  
  def ancestors
    self.class.find(:all, :order => 'version',
      :conditions => ['auditable_id = ? and auditable_type = ? and version <= ?',
      auditable_id, auditable_type, version])
  end
  
  def self.reconstruct_attributes(audits)
    changes = {}
    result = audits.collect do |audit|
      changes.merge!(Hash[*(audit.changes || {}).collect { |k, v| [k, v.first] }.flatten].merge!(:version => audit.version))
      yield changes if block_given?
    end
    block_given? ? result : changes
  end

  private

  def set_version_number
    max = self.class.maximum(:version,
      :conditions => {
        :auditable_id => auditable_id,
        :auditable_type => auditable_type
      }) || 0
    self.version = max + 1
  end
  
  protected

  def self.search(query, options = {})
    options[:order] ||= 'created_at DESC'

    paginate options
  end

  public

  # Checks if this audit represents the auditable's lastest revision.
  def latest_revision_of_auditable?
    max = self.class.maximum(:version,
      :conditions => {
        :auditable_id => auditable_id,
        :auditable_type => auditable_type
      })
    max == version
  end

  # Reconstructs the auditable's state as per its previous revision.
  def previous_revision_of_auditable
    auditable.revision(:previous)
  end
end
