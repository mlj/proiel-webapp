class Token < ActiveRecord::Base
  INFO_STATUSES = [:new, :acc, :acc_gen, :acc_sit, :acc_inf, :old, :old_inact, :no_info_status, :info_unannotatable]

  belongs_to :sentence
  belongs_to :lemma
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  belongs_to :head, :class_name => 'Token'
  has_many :dependents, :class_name => 'Token', :foreign_key => 'head_id'
  belongs_to :relation
  belongs_to :morphology

  has_many :slash_out_edges, :class_name => 'SlashEdge', :foreign_key => 'slasher_id', :dependent => :destroy
  has_many :slash_in_edges, :class_name => 'SlashEdge', :foreign_key => 'slashee_id', :dependent => :destroy
  has_many :slashees, :through => :slash_out_edges
  has_many :slashers, :through => :slash_in_edges

  belongs_to :token_alignment, :class_name => 'Token', :foreign_key => 'token_alignment_id'
  belongs_to :dependency_alignment, :class_name => 'Token', :foreign_key => 'dependency_alignment_id'
  has_many :dependency_alignment_terminations

  has_many :anaphors, :class_name => 'Token', :foreign_key => 'antecedent_id', :dependent => :nullify
  belongs_to :antecedent, :class_name => 'Token', :foreign_key => 'antecedent_id'

  before_validation :before_validation_cleanup

  searchable_on :form

  named_scope :word, :conditions => ["empty_token_sort IS NULL"]
  named_scope :morphology_annotatable, :conditions => ["empty_token_sort IS NULL"]
  named_scope :dependency_annotatable, :conditions => ["empty_token_sort IS NULL OR empty_token_sort != 'P'"]
  named_scope :morphology_annotated, :conditions => [ "lemma_id IS NOT NULL" ]

  # Tokens that are candidate root nodes in dependency graphs.
  named_scope :root_dependency_tokens, :conditions => [ "head_id IS NULL" ]

  # Tokens that belong to source +source+.
  named_scope :by_source, lambda { |source|
    { :conditions => { :sentence_id => source.source_divisions.map(&:sentences).flatten.map(&:id) } }
  }

  acts_as_audited :except => [:source_morphology, :source_lemma, :tracked_references]

  # General schema-defined validations
  validates_presence_of :sentence_id
  validates_presence_of :token_number

  # Constraint: t.sentence.reviewed_by => t.lemma_id
  validates_presence_of :lemma, :if => lambda { |t| t.is_morphtaggable? and t.sentence.reviewed_by }

  # Constraint: t.lemma_id <=> t.morphology
  validates_presence_of :lemma, :if => lambda { |t| t.morphology }
  validates_presence_of :morphology, :if => lambda { |t| t.lemma }

  # Constraint: t.head_id => t.relation
  validates_presence_of :relation, :if => lambda { |t| !t.head_id.nil? }

  # If set, source_morphology must have the correct length.
  validates_length_of :source_morphology, :allow_nil => true, :is => MorphFeatures::MORPHOLOGY_LENGTH

  # FIXME: validate morphology vs language?
  #validates_inclusion_of :morphology, :in => MorphFeatures.morphology_tag_space(language.iso_code)

  # form must be on the appropriate Unicode normalization form
  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM

  validates_inclusion_of :info_status, :allow_nil => true, :in => INFO_STATUSES

  # Specific validations
  validate :validate_sort

  # Sets the relation for the token. The relation may be a Relation
  # object, a string with the relation tag or a symbol with the
  # relation tag.
  def relation=(r)
    case r
    when Relation
      write_attribute(:relation_id, r.id)
    else
      if r.blank?
        write_attribute(:relation_id, nil)
      else
        r = Relation.find_by_tag(r.to_s)
        raise ArgumentError, 'invalid relation' unless r
        write_attribute(:relation_id, r.id)
      end
    end
  end

  # Returns the language for the token.
  def language
    sentence.language
  end
  
  # Returns the nearest anaphor for the token.
  def anaphor
    anaphors.min { |x, y| x.antecedent_dist_in_words <=> y.antecedent_dist_in_words }
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

  alias :next :next_token
  alias :previous :previous_token

  include Ordering

  def ordering_attribute
    :token_number
  end

  def ordering_collection
    sentence.tokens
  end

  # Returns the morphological features for the token or +nil+ if none
  # are set.
  def morph_features
    # We can rely on the invariant !lemma.blank? <=>
    # !morphology.blank?
    if lemma
      MorphFeatures.new(lemma, morphology)
    else
      nil
    end
  end

  # Sets the morphological features for the token. Executes a +save!+
  # on the token object, which will result in validation of all token
  # attributes. Will also create a new Lemma object if necessary.
  # Returns the morphological features. It is guaranteed that no
  # updating will take place if the morph-features are unchanged.
  def morph_features=(f)
    Token.transaction do
      if f.nil?
        self.morphology = nil
        self.lemma = nil
        self.save!
      elsif f.is_a?(String)
        s1, s2, s3, s4 = f.split(',')
        self.morph_features = MorphFeatures.new([s1, s2, s3].join(','), s4)
      elsif self.morphology != f.morphology or f.lemma.new_record? or f.lemma != self.lemma
        self.morphology = f.morphology
        f.lemma.save! if f.lemma.new_record?
        self.lemma = f.lemma
        self.save!
      end
    end

    f
  end

  # Returns the source morphological features for the token or nil if
  # none are set.
  def source_morph_features
    # Source morph-features may be incomplete, so if any of the
    # relevant fields are set we should return an object. We will have
    # to pass along the language, as the +source_lemma+ attribute is a
    # serialized lemma specification without language code.
    if source_lemma or source_morphology
      MorphFeatures.new([source_lemma, language.iso_code].join(','), source_morphology)
    else
      nil
    end
  end

  # Sets the source morphological features for the token. Executes a
  # +save!+ on the token object, which will result in validation of
  # all token attributes.  Returns the morphological features. It is
  # guaranteed that no updating will take place if the morph-features
  # are unchanged.
  def source_morph_features=(f)
    Token.transaction do
      if f.nil?
        self.source_morphology = nil
        self.source_lemma = nil
        self.save!
      elsif f.is_a?(String)
        s1, s2, s3, s4 = f.split(',')
        self.source_morph_features = MorphFeatures.new([s1, s2, s3].join(','), s4)
      elsif self.source_morphology != f.morphology or f.lemma_s != self.source_lemma
        self.source_morphology = f.morphology
        self.source_lemma = f.lemma_s
        self.save!
      end
    end
  end

  # Infers morph-features by invoking the morphological tagger. If morph-features
  # are already present these take precedence.
  def inferred_morph_features
    result, pick, *suggestions = language.guess_morphology(form, morph_features || source_morph_features)
    [pick, *suggestions]
  end

  # Relation predicates to be delegated to Relation.
  RELATION_TESTS = [:predicative?, :nominal?, :appositive?]

  # Delegate morphological feature tests to the morph-features class.
  def method_missing(n)
    if MorphFeatures::POS_PREDICATES.include?(n)
      # Morph-feature predicates to be delegated to MorphFeatures
      morph_features and morph_features.send(n)
    elsif MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.include?(n)
      # Morph-feature field accessors to be delegated to MorphFeatures.
      morph_features and morph_features.send(n)
    elsif RELATION_TESTS.include?(n)
      relation and relation.send(n)
    else
      super
    end
  end

  # Returns true if the token is a verb. If +include_empty_tokens+ is
  # true, also returns true for an empty node with its empty token
  # sort set to verb.
  def verb?(include_empty_tokens = true)
    (include_empty_tokens && empty_token_sort == 'V') || (morph_features and morph_features.verb?)
  end

  # Returns true if the token is a conjunction. If +include_empty_tokens+ is
  # true, also returns true for an empty node with its empty token
  # sort set to conjunction.
  def conjunction?(include_empty_tokens = true)
    (include_empty_tokens && empty_token_sort == 'C') || (morph_features and morph_features.conjunction?)
  end

  def parent
    sentence
  end

  include References

  def reference_parent
    sentence
  end

  # Returns true if this is an empty token, i.e. a token used for empty nodes
  # in dependency structures.
  def is_empty?
    !empty_token_sort.nil?
  end

  # Returns true if this is a token that takes part in morphology tagging.
  def is_morphtaggable?
    empty_token_sort.nil?
  end

  # Merges the token with the token linearly subsequent to it. The succeeding
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

  # Returns the dependency subgraph for the token as an unordered list.
  def subgraph_set
    [self] + dependents.map(&:subgraph_set).flatten
  end

  # Returns the dependency alignment subgraph for the token as an unordered
  # list.
  def dependency_alignment_subgraph_set(aligned_source)
    unless is_dependency_alignment_terminator?(aligned_source)
      [self] + dependents.map { |d| d.dependency_alignment_subgraph_set(aligned_source) }.flatten
    else
      []
    end
  end

  # Returns true if token is a terminator in dependency alignment.
  def is_dependency_alignment_terminator?(aligned_source)
    not dependency_alignment_terminations.count(:conditions => { :source_id => aligned_source.id }).zero?
  end

  # Returns the dependency alignment set that the token is a member of, i.e.
  # an unordered list of tokens that are members of two dependency aligned
  # subgraphs or an empty list if the token is unaligned. The total number
  # of edges traversed before an alignment was identified is also returned.
  # The results are returned as a pair consisting of the list and the
  # edge count.
  def dependency_alignment_set
    alignment = best_dependency_alignment

    if alignment
      primary, secondary, edge_count = alignment

      # Grab both subgraphs
      [primary.dependency_alignment_subgraph_set(secondary.sentence.source_division.source) +
       secondary.dependency_alignment_subgraph_set(primary.sentence.source_division.source), edge_count]
    else
      # No best dependency alignment.
      [[], 0]
    end
  end

  # Returns the best dependency alignment available. If none exists, the
  # sentence alignment is returned. The alignment is returned as a triple
  # of token IDs and the number of edges traversed before an alignment
  # was found, or if none exists, +nil+.
  def best_dependency_alignment
    aligned_source = sentence.source_division.aligned_source_division.source

    # Traverse the tree up until we find a dependency alignment edge or
    # the root node.
    t = self
    edge_count = 0

    while t and not t.dependency_alignment
      # If we've found a terminator we abort here.
      return nil if t.is_dependency_alignment_terminator?(aligned_source)

      t = t.head
      edge_count += 1
    end

    if t and t.dependency_alignment
      [t, t.dependency_alignment, edge_count]
    elsif sentence.sentence_alignment
      [sentence.root_dependency_token, sentence.sentence_alignment.root_dependency_token, edge_count]
    else
      nil
    end
  end

  PREDICATIVE_AND_APPOSITIVE_RELATIONS = %w(xobj xadv apos)
  NOMINAL_RELATIONS = %w(part obl sub obj narg voc)

  # Returns true if the token has a nominal POS or a nominal syntactic relation,
  # or if one of its dependents is an article.
  def is_annotatable?
    info_status == :no_info_status || # manually marked as annotatable
      (info_status != :info_unannotatable && \
        !conjunction? && !relative_pronoun? && !predicative? && !appositive? &&
        (noun? || pronoun? || nominal? || dependents.any?(&:article?)))
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

  private

  def self.tokens_in_same_source?(t1, t2)
    t1.sentence.source_division.source == t2.sentence.source_division.source
  end

  def self.tokens_in_contiguous_source_divisions?(t1, t2)
    t1.sentence.source_division.source.source_divisions.count(:all, :conditions => ['position between ? and ?', t1.sentence.source_division.position, t2.sentence.source_division.position]) < 3
  end

  public

  # Returns the distance between two tokens measured in number of sentences.
  # first_token is supposed to precede second_token.
  def self.sentence_distance_between(first_token, second_token)
    raise "Tokens must be in the same source" unless self.tokens_in_same_source?(first_token, second_token)
    raise "The two tokens are not in contiguous source divisions" unless self.tokens_in_contiguous_source_divisions?(first_token, second_token)

    if first_token.sentence.source_division == second_token.sentence.source_division
      first_token.sentence.source_division.sentences.count(:all, :conditions => ['sentence_number BETWEEN ? AND ?',
                                                                                 first_token.sentence.sentence_number,
                                                                                 second_token.sentence.sentence_number]) - 1
    else
      first_token.sentence.source_division.sentences.count(:all, :conditions => ['sentence_number > ?',
                                                                                 first_token.sentence.sentence_number]) + second_token.sentence.source_division.sentences.count(:all, :conditions => ['sentence_number < ?', second_token.sentence.sentence_number ]) + 1
    end
  end

  # Returns the distance between two tokens measured in number of words.
  # first_token must precede second_token.
  def self.word_distance_between(first_token, second_token)
    raise "Tokens must be in the same source" unless self.tokens_in_same_source?(first_token, second_token)
    raise "The two tokens are not in contiguous source divisions" unless self.tokens_in_contiguous_source_divisions?(first_token, second_token)

    first_token = first_token.head if first_token.empty_token_sort == 'P'
    second_token = second_token.head if second_token.empty_token_sort == 'P'

    if first_token.sentence.sentence_number == second_token.sentence.sentence_number and first_token.sentence.source_division == second_token.sentence.source_division
      num_words = first_token.sentence.tokens.word.count(:conditions => ['token_number BETWEEN ? AND ?',
                                                                         first_token.token_number,
                                                                         second_token.token_number - 1])
    else
      # Find the number of words following (and including) the first token in its sentence
      num_words = first_token.sentence.tokens.word.count(:conditions => ['token_number >= ?', first_token.token_number])

      # Find the number of words preceding the second token in its sentence
      num_words += second_token.sentence.tokens.word.count(:conditions => ['token_number < ?', second_token.token_number])

      # Check whether the two tokens are in the same source_division
      if first_token.sentence.source_division == second_token.sentence.source_division
        # Find the number of words in intervening sentences of the same source_division
        first_token.sentence.source_division.sentences.find(:all, :conditions => ['sentence_number BETWEEN ? AND ?',
                                                                                  first_token.sentence.sentence_number + 1,
                                                                                  second_token.sentence.sentence_number - 1]).each do |sentence|
          num_words += sentence.tokens.word.count
        end
      else
        # Find the number of words in sentences following the first token's sentence in its source_division
        first_token.sentence.source_division.sentences.find(:all, :conditions => ['sentence_number > ?',
                                                                                  first_token.sentence.sentence_number]).each do |sentence|
          num_words += sentence.tokens.word.count
        end
        # Find the number of words preceding the second token in its source_division
        second_token.sentence.source_division.sentences.find(:all, :conditions => ['sentence_number < ?',
                                                                                   second_token.sentence.sentence_number]).each do |sentence|
          num_words += sentence.tokens.word.count
        end
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
    # morphology, source_morphology, lemma and source_lemma may only
    # be set if token is morphtaggable
    unless is_morphtaggable?
      errors.add(:morphology, "not allowed on non-morphtaggable token") unless morphology.nil?
      errors.add(:source_morphology, "not allowed on non-morphtaggable token") unless morphology.nil?
      errors.add(:lemma, "not allowed on non-morphtaggable token") unless lemma.nil?
      errors.add(:source_lemma, "not allowed on non-morphtaggable token") unless source_lemma.nil?
    end

    # if morph-features are set, are they valid?
    if m = morph_features
      errors.add_to_base("morph-features #{m.to_s} are invalid") unless m.valid?
    end

    # sort :empty_dependency_token <=> form.nil?
    if is_empty? or form.nil?
      errors.add_to_base("Empty tokens must have NULL form") unless is_empty? and form.nil?
    end
  end

  private

  def before_validation_cleanup
    self.morphology = nil if morphology.blank?
    self.lemma_id = nil if lemma_id.blank?
    self.source_morphology = nil if source_morphology.blank?
    self.source_lemma = nil if source_lemma.blank?
    self.foreign_ids = nil if foreign_ids.blank?
    self.empty_token_sort = nil if empty_token_sort.blank?
    self.form = nil if form.blank?
  end

  public

  def to_s
    form
  end
end
