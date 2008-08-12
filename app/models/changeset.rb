class Changeset < ActiveRecord::Base
  belongs_to :user
  has_many :changes, :class_name => 'Audit'

#  validates_presence_of :changes, :message => 'is empty'

  protected

  def self.search(query, options = {})
    options[:order] ||= 'created_at DESC'

    paginate options
  end
end
