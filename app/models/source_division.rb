class SourceDivision < ActiveRecord::Base
  belongs_to :source
  has_many :sentences, :order => 'sentence_number ASC'
  has_many :tokens, :through => :sentences, :order => 'sentences.sentence_number ASC, token_number ASC'
  belongs_to :alignment_source_division

  # Returns a citation-form reference for this source division.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  def citation(options = {})
    [source.citation(options), options[:abbreviated] ? abbreviated_title : title] * ' '
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['title LIKE ?', "%#{query}%"] unless query.blank?

    paginate options
  end
end
