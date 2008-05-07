class Source < ActiveRecord::Base
  validates_presence_of :title
  validates_uniqueness_of :title

  has_many :books, :class_name => 'Book', :finder_sql => 'SELECT books.* FROM books AS books LEFT JOIN sentences AS sentences ON book_id = books.id WHERE source_id = #{id} GROUP BY book_id'
  has_many :sentences
  has_many :tokens, :class_name => 'Token', :finder_sql => 'SELECT * FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id WHERE source_id = #{id}', :counter_sql => 'SELECT count(*) FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id WHERE source_id = #{id}' 

  has_many :unannotated_sentences, :class_name => 'Sentence', :foreign_key => 'source_id', :conditions => 'annotated_by is null'
  has_many :annotated_sentences, :class_name => 'Sentence', :foreign_key => 'source_id', :conditions => 'annotated_by is not null'
  has_many :reviewed_sentences, :class_name => 'Sentence', :foreign_key => 'source_id', :conditions => 'reviewed_by is not null'

  belongs_to :aligned_with, :class_name => 'Source', :foreign_key => 'alignment_id' 
  has_many :bookmarks

  # FIXME: These don't really belong here, do they? But where should
  # they go instead?
  class << self
    # Returns information about the level of activity. The information is returned
    # per day, and for freshly annotated sentences. Does not include the present
    # day, since activity may not yet have ceased.
    def activity
      Sentence.count(:all, :conditions => "annotated_at is not null AND annotated_at < DATE_FORMAT(NOW(), '%Y-%m-%d')", :group => "DATE_FORMAT(annotated_at, '%Y-%m-%d')", :order =>"annotated_at ASC")
   end

    # Returns completion information. If +source+ is given, then information is returned
    # only for this particular source.
    def completion(source = nil)
      sources = Source.find(source || :all)
      sources = [sources] unless sources.is_a?(Array)
      r = {}
      r[:reviewed] = sources.sum { |s| s.reviewed_sentences.count }
      r[:annotated] = sources.sum { |s| s.annotated_sentences.count }
      r[:unannotated] = sources.sum { |s| s.unannotated_sentences.count }
      r
    end
  end

  # Invokes the PROIEL morphology tagger. Takes any already set morphology
  # as well as any source morph+lemma tag into account.
  def invoke_tagger(form, sort, existing_morph_lemma_tag = nil, options = {})
    TAGGER.logger = logger
    TAGGER.tag_token(self.language, form, sort, existing_morph_lemma_tag, options)
  end

  # Returns the human-readable presentation form of the name of the source.
  def presentation_form
    self.title
  end

  # Export source as PROIEL text XML.
  #
  # ==== Options
  # reviewed_only:: Only include reviewed sentences. Default: +false+.
  # dependencies:: Include dependency structure annotation. Default: +true+.
  # morphology:: Include morphological annotation. Default: +true+.
  def export(filename, options = {})
    options.assert_valid_keys(:reviewed_only, :dependencies, :morphology)
    options.reverse_merge! :reviewed_only => false, :dependencies => true,
      :morphology => true
    src = self

    PROIEL::Writer.new(filename, self.code, self.language, {
      :title => self.title,
      :edition => self.edition,
      :source => self.source,
      :editor => self.editor,
      :url => self.url,
    }) do
      ss = options[:reviewed_only] ? src.reviewed_sentences : src.sentences
      ss.each do |sentence|
        sentence.tokens.each do |token|
          # Skip empty nodes unless we include dependencies
          next if token.empty? and not options[:dependencies]

          track_references(sentence.book.code, sentence.chapter, token.verse)

          attributes = {}

          if options[:dependencies]
            attributes[:id] = token.id
            attributes[:relation] = token.relation if token.relation
            attributes[:head] = token.head_id if token.head
            attributes[:slashes] = token.slashees.collect { |s| s.id }.join(' ') unless token.slashees.empty?
          end

          if options[:morphology]
            attributes[:morphtag] = token.morphtag if token.morphtag
            attributes[:lemma] = token.lemma.presentation_form if token.lemma
          end

          attributes[:sort] = token.sort.to_s.gsub(/_/, '-')
          attributes['composed-form'] = token.composed_form if token.composed_form

          emit_word(token.form, attributes)
        end
        next_sentence
      end
    end
  end

  protected

  def self.search(search, page)
    search ||= {}
    conditions = [] 
    clauses = [] 
    includes = []

    paginate(:page => page, :per_page => 50, :conditions => conditions, 
             :include => includes)
  end
end
