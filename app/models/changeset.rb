class Changeset < ActiveRecord::Base
  belongs_to :changer, :polymorphic => true
  has_many :changes, :class_name => 'Audit'

#  validates_presence_of :changes, :message => 'is empty'

  def user
    self.changer.is_a?(User) ? self.changer : self.changer.user
  end

  protected

  def self.search(search, page)
    search ||= {}
    conditions = []
    clauses = []
    includes = []

    if search[:user] and search[:user] != ''
      clauses << "(changer_type = 'User' and changer_id = ?)"
      conditions << search[:user] 
    end

    conditions = [clauses.join(' and ')] + conditions

    paginate(:page => page, :per_page => 50, :order => 'created_at DESC', 
             :include => includes, :conditions => conditions)
  end
end
