class Source < ActiveRecord::Base
  validates_presence_of :title
  validates_uniqueness_of :title

  belongs_to :language
  has_many :books, :class_name => 'Book', :finder_sql => 'SELECT books.* FROM books AS books LEFT JOIN sentences AS sentences ON book_id = books.id WHERE source_id = #{id} GROUP BY book_id'
  has_many :sentences, :order => 'sentence_number ASC'
  has_many :tokens, :through => :sentences, :order => 'sentences.sentence_number ASC, token_number ASC'

  has_many :annotated_sentences, :class_name => 'Sentence', :foreign_key => 'source_id', :conditions => 'annotated_by is not null'
  has_many :reviewed_sentences, :class_name => 'Sentence', :foreign_key => 'source_id', :conditions => 'reviewed_by is not null'

  belongs_to :aligned_with, :class_name => 'Source', :foreign_key => 'alignment_id' 
  has_many :bookmarks

  # FIXME: this should be an instance method on Book (or its equivalence), when
  # Book has been changed to a first order object.
  # Returns the perecentage of annotated senteces to unannotated sentences the
  # book +book_id+ in the source.
  def book_completion_ratio(book_id)
    Sentence.count_by_sql("SELECT count(annotated_by) * 100 / count(*) FROM sentences WHERE source_id = #{id} AND book_id = #{book_id}")
  end

  # Returns the human-readable presentation form of the name of the source.
  def presentation_form
    self.title
  end

  protected

  def self.search(query, options)
    options[:conditions] ||= ["title LIKE ?", "%#{query}%"] unless query.blank?

    paginate options
  end
end
