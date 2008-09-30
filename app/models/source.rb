class Source < ActiveRecord::Base
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_each :metadata do |record, attr, value|
    record.errors.add :tei_header, "invalid: #{value.error_message}" unless value.valid?
  end

  belongs_to :language
  has_many :source_divisions, :order => [:position]
  has_many :bookmarks

  composed_of :metadata, :class_name => 'Metadata', :mapping => %w(tei_header)

  # Returns a citation-form reference for this source.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  def citation(options = {})
    options[:abbreviated] ? abbreviation : title
  end

  protected

  def self.search(query, options)
    options[:conditions] ||= ["title LIKE ?", "%#{query}%"] unless query.blank?

    paginate options
  end
end
