class ImportSource < ActiveRecord::Base
  has_many :notes, :as => :notable

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['summary = ?', "%#{query}%"] unless query.blank?
    options[:order] ||= 'created_at ASC'

    paginate options
  end
end
