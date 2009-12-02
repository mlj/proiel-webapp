class Note < ActiveRecord::Base
  belongs_to :originator, :polymorphic => true
  belongs_to :notable, :polymorphic => true

  def name_of_originator
    originator.full_name.freeze
  end

  def note_applies_to
    "#{notable.class} #{notable.id}".freeze
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['contents LIKE ?', "%#{query}%"] unless query.blank?
    options[:order] ||= 'created_at ASC'

    paginate options
  end
end
