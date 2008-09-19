class SourceDivision < ActiveRecord::Base
  belongs_to :source
  has_many :sentences, :order => 'sentence_number ASC'
  has_many :tokens, :through => :sentences, :order => 'sentences.sentence_number ASC, token_number ASC'
  belongs_to :aligned_source_division, :class_name => "SourceDivision"

  # Returns a citation-form reference for this source division.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  def citation(options = {})
    [source.citation(options), options[:abbreviated] ? abbreviated_title : title] * ' '
  end

  def sentence_alignments(options = {})
    # FIXME: how is it best to determine where the main divisions should be? Edit the whole
    # book at once with a paginated view and chapters used to insert default anchors? One
    # editor view per chapter? Source divisions per chapter?
    options[:chapter] = 3

    if aligned_source_division
      base_sentences = sentences.by_chapter(options[:chapter])
      aligned_sentences = aligned_source_division.sentences.by_chapter(options[:chapter])

      align_sentences(aligned_sentences, base_sentences)
    else
      []
    end
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['title LIKE ?', "%#{query}%"] unless query.blank?

    paginate options
  end
end
