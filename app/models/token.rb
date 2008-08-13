class Token < ActiveRecord::Base
  belongs_to :sentence
  belongs_to :book
  belongs_to :lemma

  belongs_to :head, :class_name => 'Token'
  has_many :dependents, :class_name => 'Token', :foreign_key => 'head_id'

  has_many :slash_out_edges, :class_name => 'SlashEdge', :foreign_key => 'slasher_id'
  has_many :slash_in_edges, :class_name => 'SlashEdge', :foreign_key => 'slashee_id'
  has_many :slashees, :through => :slash_out_edges
  has_many :slashers, :through => :slash_in_edges

  acts_as_audited :except => [ :morphtag_performance ]
  # Insanely slow! We use our own implementation instead.
  #acts_as_ordered :order => :token_number

  # General schema-defined validations
  validates_presence_of :sentence_id
  validates_presence_of :verse, :unless => :is_empty?
  validates_presence_of :token_number
  validates_presence_of :sort

  # Constraint: t.sentence.reviewed_by => t.lemma_id
  validates_presence_of :lemma, :if => lambda { |t| t.is_morphtaggable? and t.sentence.reviewed_by }

  # Constraint: t.lemma_id <=> t.morphtag
  validates_presence_of :lemma, :if => lambda { |t| t.morphtag }
  validates_presence_of :morphtag, :if => lambda { |t| t.lemma }

  # Constraint: t.head_id => t.relation
  validates_presence_of :relation, :if => lambda { |t| !t.head_id.nil? }

  validate do |t|
    if t.relation and not PROIEL::RELATIONS.valid?(t.relation)
      errors.add_to_base("Relation #{t.relation} is invalid")
    end
  end

  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM
  validates_unicode_normalization_of :presentation_form, :form => UNICODE_NORMALIZATION_FORM

  # Specific validations
  validate :validate_sort

  def previous_tokens
    self.sentence.tokens.find(:all, 
                              :conditions => [ "token_number < ?", self.token_number ], 
                              :order => "token_number ASC")
  end

  def next_tokens
    self.sentence.tokens.find(:all, 
                              :conditions => [ "token_number > ?", self.token_number ], 
                              :order => "token_number ASC")
  end

  # Returns the previous token in the linearisation sequence. Returns +nil+
  # if there is no previous token.
  def previous_token
    self.sentence.tokens.find(:first, 
                              :conditions => [ "token_number < ?", self.token_number ], 
                              :order => "token_number DESC")
  end

  # Returns the next token in the linearisation sequence. Returns +nil+
  # if there is no next token.
  def next_token
    self.sentence.tokens.find(:first, 
                              :conditions => [ "token_number > ?", self.token_number ], 
                              :order => "token_number ASC")
  end

  def morph
    PROIEL::MorphTag.new(morphtag)
  end

  # Returns the morph+lemma tag for the token or +nil+ if none
  # is set.
  def morph_lemma_tag
    if self.morphtag
      if lemma
        PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new(morphtag), 
                                  lemma.lemma, lemma.variant)
      else
        PROIEL::MorphLemmaTag.new(morphtag)
      end
    else
      nil
    end
  end

  # Sets morphology and lemma based on a morph+lemma tag. Saves the
  # token.
  def set_morph_lemma_tag!(ml_tag)
    returning Lemma.find_or_create_by_morph_and_lemma_tag_and_language(ml_tag, self.language) do |l|
      self.morphtag = ml_tag.morphtag.to_s
      self.lemma_id = l.id
      self.save!
    end
  end

  # Returns the source morph+lemma tag for the token or +nil+ if
  # none is set.
  def source_morph_lemma_tag
    if self.source_morphtag
      PROIEL::MorphLemmaTag.new(self.source_morphtag, self.source_lemma)
    else
      nil
    end
  end

  # Returns true if the morphtag is valid.
  def morphtag_is_valid?
    PROIEL::MorphTag.new(morphtag).is_valid?(language)
  end

  # Returns true if the source morphtag is valid.
  def source_morphtag_is_valid?
    PROIEL::MorphTag.new(source_morphtag).is_valid?(language)
  end

  def reference
    if verse
      PROIEL::Reference.new(sentence.source.abbreviation, sentence.source.id,
                    sentence.book.code, sentence.book.id,
                    { :chapter => sentence.chapter.to_i, 
                      :verse => verse.to_i, 
                      :sentence => sentence.sentence_number.to_i, 
                      :token => token_number.to_i })
    else
      PROIEL::Reference.new(sentence.source.abbreviation, sentence.source.id,
                    sentence.book.code, sentence.book.id,
                    { :chapter => sentence.chapter.to_i, 
                      :sentence => sentence.sentence_number.to_i, 
                      :token => token_number.to_i })
    end
  end

  # Updates dependency annotation for the token and saves the record.
  def update_dependencies!(head, relation)
    self.head_id = head
    self.relation = relation
    save!
  end

  # Clears dependency annotation for the token and saves the record.
  def clear_dependencies!
    update_dependencies!(nil, nil)
  end

  # Returns true if this is an empty token, i.e. a token used for empty nodes
  # in dependency structures.
  def is_empty?
    PROIEL::EMPTY_TOKEN_SORTS.include?(sort)
  end

  # Returns true if this is a token that takes part in morphology tagging.
  def is_morphtaggable?
    PROIEL::MORPHTAGGABLE_TOKEN_SORTS.include?(sort)
  end

  # Invokes the PROIEL morphology tagger. Takes exitsing information into
  # account, be it already existing morph+lemma tags or previous instances
  # of the same token form.
  def invoke_tagger
    TAGGER.logger = logger
    TAGGER.tag_token(self.language, self.form,
                     self.morph_lemma_tag || self.source_morph_lemma_tag)
  end

  # Returns the language of the token.
  def language
    # FIXME: eliminate to_sym
    sentence.source.language.to_sym
  end 

  # Merges the token with the token linearly subsequent to it. The succeding
  # token is destroyed, and the original token's word form is updated. All
  # other data is left as-is. Returns the new merged token.
  def merge!(separator = ' ')
    Token.transaction do
      n = self.next_token
      self.form = [self.form, n.form].join(separator)
      self.save!
      n.destroy
    end
    self
  end

  protected

  def self.search(search, page, limit = 50)
    search ||= {}
    conditions = [] 
    clauses = [] 
    includes = []

    if search[:source] and search[:source] != ''
      clauses << "sentences.source_id = ?"
      conditions << search[:source]
      includes << :sentence
    end
    
    if search[:form] and search[:form] != ''
      if search[:exact] == 'yes'
        clauses << "form = ?"
        conditions << "#{search[:form]}"
      else
        clauses << "form like ?"
        conditions << "%#{search[:form]}%"
      end
    end

    conditions = [clauses.join(' and ')] + conditions

    paginate(:page => page, :per_page => limit, :conditions => conditions, 
             :include => includes)
  end

  private

  def validate_sort
    # morphtag and morphtag source may only be set 
    # if token is morphtaggable
    unless is_morphtaggable?
      errors.add(:morphtag, "not allowed on non-morphtaggable token") unless morphtag.nil?
      errors.add(:morphtag_source, "not allowed on non-morphtaggable token") unless morphtag_source.nil?
    end

    # if morphtag is set, is it valid?
    errors.add_to_base("Morphological annotation #{morphtag.inspect} is invalid") if morphtag and !PROIEL::MorphTag.new(morphtag).is_valid?(self.language)

    # if morphtag is set, is it actually a morphtag or just a blank?
    if morphtag
      errors.add(:morphtag, "is blank (probably should be NULL)") if morphtag == ''
      errors.add(:morphtag, "is blank (probably should be NULL)") if morphtag == PROIEL::MorphTag.new().to_s 
    end

    # sort :empty_dependency_token <=> form.nil?
    if sort == :empty_dependency_token or sort == :lacuna_start or sort == :lacuna_end or form.nil?
      errors.add_to_base("Empty tokens must have NULL form and sort set to 'empty_dependency_token' or 'lacuna'") unless (sort == :empty_dependency_token or sort == :lacuna_start or sort == :lacuna_end) and form.nil?
    end

    # sort :presentation_form <=> :presentation_span <=> (contraction || emendation || abbreviation || capitalisation)
    if !presentation_form.nil? or !presentation_span.nil? or contraction or emendation or abbreviation or capitalisation
      errors.add_to_base("Tokens with presentation form must have presentation_form set") if presentation_form.nil?
      errors.add_to_base("Tokens with presentation form must have presentation_span set") if presentation_span.nil?
      errors.add_to_base("Tokens with presentation form must have one of contraction, emendation, abbreviation or capitalisation set") unless contraction or emendation or abbreviation or capitalisation
    end
  end
end
