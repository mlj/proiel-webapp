class Note < ActiveRecord::Base
  belongs_to :originator, :polymorphic => true
  belongs_to :notable, :polymorphic => true

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['contents LIKE ?', "%#{query}%"] unless query.blank?
    options[:order] ||= 'created_at ASC'

    paginate options
  end
end
