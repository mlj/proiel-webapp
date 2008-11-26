class Token < ActiveRecord::Base
  INFO_STATUSES = [:new, :acc, :acc_gen, :acc_disc, :acc_inf, :old, :no_info_status, :info_unannotatable]

  belongs_to :sentence
  belongs_to :lemma
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  belongs_to :head, :class_name => 'Token'
  has_many :dependents, :class_name => 'Token', :foreign_key => 'head_id'

  has_many :slash_out_edges, :class_name => 'SlashEdge', :foreign_key => 'slasher_id', :dependent => :destroy
  has_many :slash_in_edges, :class_name => 'SlashEdge', :foreign_key => 'slashee_id', :dependent => :destroy
  has_many :slashees, :through => :slash_out_edges
  has_many :slashers, :through => :slash_in_edges

  belongs_to :token_alignment, :class_name => 'Token', :foreign_key => 'token_alignment_id'
  belongs_to :dependency_alignment, :class_name => 'Token', :foreign_key => 'dependency_alignment_id'
  has_many :dependency_alignment_terminations

  has_one :antecedent, :class_name => 'Token', :foreign_key => 'anaphor_id', :dependent => :nullify
  belongs_to :anaphor, :class_name => 'Token'

  searchable_on :form

  named_scope :word, :conditions => { :sort => :text }
  named_scope :morphology_annotatable, :conditions => { :sort => PROIEL::MORPHTAGGABLE_TOKEN_SORTS }
  named_scope :dependency_annotatable, :conditions => { :sort => PROIEL::DEPENDENCY_TOKEN_SORTS }

  # Tokens that belong to source +source+.
  named_scope :by_source, lambda { |source|
    { :conditions => { :sentence_id => source.source_divisions.map(&:sentences).flatten.map(&:id) } }
  }

  acts_as_audited

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

  # If set, relation must be valid.
  validates_inclusion_of :relation, :allow_nil => true, :in => PROIEL::RELATIONS.keys.map(&:to_s)

  # If set, morphtag and source_morphtag must have the correct length.
  validates_length_of :morphtag, :allow_nil => true, :is => PROIEL::MorphTag.fields.length
  validates_length_of :source_morphtag, :allow_nil => true, :is => PROIEL::MorphTag.fields.length

  # form and presentation_form must be on the appropriate Unicode normalization form
  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM
  validates_unicode_normalization_of :presentation_form, :form => UNICODE_NORMALIZATION_FORM

  validates_inclusion_of :info_status, :allow_nil => true, :in => INFO_STATUSES

  # Specific validations
  validate :validate_sort

  def language
    sentence.language
  end

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
    returning language.lemmata.find_or_create_by_morph_and_lemma_tag(ml_tag) do |l|
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
    PROIEL::MorphTag.new(morphtag).is_valid?(language.iso_code)
  end

  # Returns true if the source morphtag is valid.
  def source_morphtag_is_valid?
    PROIEL::MorphTag.new(source_morphtag).is_valid?(language.iso_code)
  end

  # Returns a citation-form reference for this token.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  # <tt>:internal</tt> -- If true, will use the internal numbering system.
  def citation(options = {})
    if options[:internal]
      [sentence.citation(options), token_number] * '.'
    else
      token_citation = [verse, token_number] * '.'
      [sentence.source_division.citation(options), token_citation] * ':'
    end
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

  # Invokes the PROIEL morphology tagger. Takes existing information into
  # account, be it already existing morph+lemma tags or previous instances
  # of the same token form.
  def invoke_tagger
    language.guess_morphology(form, morph_lemma_tag || source_morph_lemma_tag)
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

  # Returns true if the token has a nominal POS or a nominal syntactic relation,
  # or if one of its dependents is an article.
  def is_annotatable?
    if @is_annotatable.nil?
      @is_annotatable = info_status == :no_info_status ||  # manually marked as annotatable
                     (info_status != :info_unannotatable && \
                      (PROIEL::MORPHOLOGY.nominals.include?(morph[:major]) || \
                       (relation && PROIEL::RELATIONS.nominals.include?(relation.to_sym)) || \
                       dependents.any? { |dep| dep.morph[:major] == :S }))
    end
    @is_annotatable
  end

  def is_verb?
    @is_verb = morph[:major].to_s.starts_with?('V') if @is_verb.nil?
    @is_verb
  end

  # Returns all contrast groups registered for the given source division
  def self.contrast_groups_for(source_division)
    connection.select_all("SELECT DISTINCT contrast_group FROM tokens, sentences " + \
                          "WHERE tokens.contrast_group IS NOT NULL AND tokens.sentence_id = sentences.id AND sentences.source_division_id = #{source_division.id}"
                          ).map { |record| record['contrast_group'] }
  end

  def self.delete_contrast(contrast_number, source_division)
    contrast_number = contrast_number.to_i
    raise 'Invalid contrast number' unless contrast_number > 0  # in case we receive something strange as params[:contrast_number]

    connection.update("UPDATE tokens, sentences SET tokens.contrast_group = NULL WHERE tokens.contrast_group LIKE '#{contrast_number}%' " + \
                      "AND tokens.sentence_id = sentences.id AND sentences.source_division_id = #{source_division.id}")
  end

  # Returns the distance between two tokens measured in number of sentences.
  # first_token is supposed to precede second_token.
  def self.sentence_distance_between(first_token, second_token)
    first_token.sentence.source_division.sentences.count(:all, :conditions => ['sentence_number BETWEEN ? AND ?',
                                                                               first_token.sentence.sentence_number,
                                                                               second_token.sentence.sentence_number]) - 1
  end

  # Returns the distance between two tokens measured in number of words (i.e., tokens with sort == 'text').
  # first_token is supposed to precede second_token.
  def self.word_distance_between(first_token, second_token)
    if first_token.sentence.sentence_number == second_token.sentence.sentence_number
      num_words = first_token.sentence.tokens.word.count(:conditions => [
                                                           'token_number BETWEEN ? AND ?',
                                                           first_token.token_number,
                                                           second_token.token_number - 1
                                                         ])
    else
      # Find the number of words following (and including) the first token in its sentence
      num_words = first_token.sentence.tokens.word.count(:conditions => ['token_number >= ?', first_token.token_number])

      # Find the number of words preceding the second token in its sentence
      num_words += second_token.sentence.tokens.word.count(:conditions => ['token_number < ?', second_token.token_number])

      # Find the number of words in intervening sentences
      first_token.sentence.source_division.sentences.find(:all, :conditions => ['sentence_number BETWEEN ? AND ?',
                                                                                first_token.sentence.sentence_number + 1,
                                                                                second_token.sentence.sentence_number - 1]).each do |sentence|
        num_words += sentence.tokens.word.count
      end
    end
    num_words
  end

  protected

  def self.search(query, options = {})
    if query.blank?
      paginate options
    else
      search_on(query).paginate options
    end
  end

  private

  def validate_sort
    # morphtag and morphtag source may only be set
    # if token is morphtaggable
    unless is_morphtaggable?
      errors.add(:morphtag, "not allowed on non-morphtaggable token") unless morphtag.nil?
    end

    # if morphtag is set, is it valid?
    errors.add_to_base("Morphological annotation #{morphtag.inspect} is invalid") if morphtag and !PROIEL::MorphTag.new(morphtag).is_valid?(self.language.iso_code)

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
