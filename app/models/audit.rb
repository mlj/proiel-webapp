class Audit < ActiveRecord::Base
  belongs_to :auditable, :polymorphic => true
  belongs_to :user

#  validates_length_of :changes, :minimum => 1, :message => 'is empty', :unless => Proc.new { |audit|
#    audit.action == 'destroy'
#  }
  
  before_create :set_version_number
  
  serialize :changes
  
  cattr_accessor :audited_classes
  self.audited_classes = []

  def current_version?
    max = self.class.maximum(:version,
      :conditions => {
        :auditable_id => auditable_id,
        :auditable_type => auditable_type
      }) || 0
    self.version == max
  end

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
      attributes = (audit.changes || {}).inject({}) do |attrs, (name, (_,value))|
        attrs[name] = value
        attrs
      end
      changes.merge!(attributes.merge!(:version => audit.version))
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
end
