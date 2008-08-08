class Changeset < ActiveRecord::Base
  belongs_to :user
  has_many :changes, :class_name => 'Audit'

#  validates_presence_of :changes, :message => 'is empty'

  protected

  def self.search(search, page)
    search ||= {}
    conditions = []
    clauses = []
    includes = []

    if search[:user] and search[:user] != ''
      clauses << "user_id = ?)"
      conditions << search[:user] 
    end

    conditions = [clauses.join(' and ')] + conditions

    paginate(:page => page, :per_page => 50, :order => 'created_at DESC', 
             :include => includes, :conditions => conditions)
  end
end
